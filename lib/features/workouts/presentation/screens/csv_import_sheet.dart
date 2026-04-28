import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/analytics/data/datasources/analytics_datasource.dart';
import '../../../../features/analytics/data/models/analytics_models.dart';
import '../../data/datasources/routine_datasource.dart';

// ── CSV parsing ───────────────────────────────────────────────────────────────

List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  final sb = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      inQuotes = !inQuotes;
    } else if (c == ',' && !inQuotes) {
      fields.add(sb.toString().trim());
      sb.clear();
    } else {
      sb.write(c);
    }
  }
  fields.add(sb.toString().trim());
  return fields;
}

// ── Parsed models ─────────────────────────────────────────────────────────────

class _ParsedExercise {
  final String csvName;
  final int sets;
  ExerciseModel? matched; // set after matching against DB

  _ParsedExercise({required this.csvName, required this.sets});
}

class _ParsedRoutine {
  final String name;
  final List<_ParsedExercise> exercises;
  bool selected;

  _ParsedRoutine({required this.name, required this.exercises})
    : selected = true;

  int get matchedCount => exercises.where((e) => e.matched != null).length;
}

List<_ParsedRoutine> extractRoutinesFromCsv(String content) {
  final lines = content.split('\n');
  if (lines.isEmpty) return [];

  // Parse header to find column indices
  final header = _parseCsvLine(lines[0]);
  final titleIdx = header.indexOf('title');
  final startIdx = header.indexOf('start_time');
  final exIdx = header.indexOf('exercise_title');
  final setIdxCol = header.indexOf('set_index');

  if (titleIdx < 0 || exIdx < 0) return [];

  // Group: routineTitle → startTime → exerciseName → maxSetIndex
  final Map<String, Map<String, Map<String, int>>> grouped = {};
  // Keep insertion order of titles to preserve "first seen = most recent"
  final titleOrder = <String>[];

  for (int i = 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;
    final row = _parseCsvLine(line);
    if (row.length <= exIdx) continue;

    final title = titleIdx < row.length ? row[titleIdx] : '';
    final startTime = startIdx < row.length ? row[startIdx] : 'unknown';
    final exName = row[exIdx];
    final setIndex = setIdxCol >= 0 && setIdxCol < row.length
        ? (int.tryParse(row[setIdxCol]) ?? 0)
        : 0;

    if (title.isEmpty || exName.isEmpty) continue;

    if (!grouped.containsKey(title)) {
      grouped[title] = {};
      titleOrder.add(title);
    }
    grouped[title]!.putIfAbsent(startTime, () => {});
    final cur = grouped[title]![startTime]![exName] ?? 0;
    grouped[title]![startTime]![exName] = max(cur, setIndex + 1);
  }

  // For each title take the first startTime (most recent = first in file)
  final routines = <_ParsedRoutine>[];
  for (final title in titleOrder) {
    final timeMap = grouped[title]!;
    final firstTime = timeMap.keys.first;
    final exMap = timeMap[firstTime]!;
    final exercises = exMap.entries
        .map((e) => _ParsedExercise(csvName: e.key, sets: e.value))
        .toList();
    routines.add(_ParsedRoutine(name: title, exercises: exercises));
  }

  return routines;
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class CsvImportSheet extends StatefulWidget {
  final String csvContent;
  final VoidCallback onImported;

  const CsvImportSheet({
    super.key,
    required this.csvContent,
    required this.onImported,
  });

  @override
  State<CsvImportSheet> createState() => _CsvImportSheetState();
}

class _CsvImportSheetState extends State<CsvImportSheet> {
  List<_ParsedRoutine> _routines = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  Future<void> _parse() async {
    setState(() => _loading = true);
    try {
      final routines = extractRoutinesFromCsv(widget.csvContent);

      // Load all DB exercises for matching
      final dbExercises = await AnalyticsDatasource().getExercises();

      for (final routine in routines) {
        for (final ex in routine.exercises) {
          // 1. Exact match by name or alias
          ex.matched = dbExercises
              .where((e) => e.matchesName(ex.csvName))
              .firstOrNull;

          // 2. Partial match fallback (normalized)
          if (ex.matched == null) {
            final q = ExerciseModel.normalize(ex.csvName);
            ex.matched = dbExercises.where((e) {
              final n = ExerciseModel.normalize(e.name);
              return n.contains(q) || q.contains(n);
            }).firstOrNull;
          }
        }
      }

      setState(() {
        _routines = routines;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final toSave = _routines.where((r) => r.selected).toList();
    if (toSave.isEmpty) return;

    setState(() => _saving = true);
    int saved = 0;
    final errors = <String>[];

    for (final routine in toSave) {
      final matchedExercises = routine.exercises
          .where((e) => e.matched != null)
          .toList();
      if (matchedExercises.isEmpty) {
        errors.add('${routine.name}: sin ejercicios reconocidos');
        continue;
      }

      try {
        await RoutineDatasource().createRoutine(
          name: routine.name,
          exercises: matchedExercises.asMap().entries.map((entry) {
            return {
              'exerciseId': entry.value.matched!.id,
              'exerciseOrder': entry.key + 1,
              'targetSeries': entry.value.sets, // legacy compat
              'series': List.generate(
                entry.value.sets,
                (j) => {'setOrder': j + 1},
              ),
            };
          }).toList(),
        );
        saved++;
      } catch (e) {
        errors.add('${routine.name}: $e');
      }
    }

    setState(() => _saving = false);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onImported();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errors.isEmpty
                ? '$saved rutina${saved != 1 ? 's' : ''} importada${saved != 1 ? 's' : ''}'
                : '$saved importada${saved != 1 ? 's' : ''}. Errores: ${errors.join(', ')}',
          ),
          backgroundColor: errors.isEmpty ? AppTheme.neonGreen : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Importar desde CSV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!_loading && !_saving)
                    TextButton(
                      onPressed: _routines.any((r) => r.selected)
                          ? _save
                          : null,
                      child: Text(
                        'Guardar',
                        style: TextStyle(
                          color: _routines.any((r) => r.selected)
                              ? AppTheme.neonGreen
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (_saving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.neonGreen,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2C2C2C), height: 1),
            Expanded(
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppTheme.neonGreen),
                          SizedBox(height: 12),
                          Text(
                            'Analizando CSV...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _routines.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron rutinas.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _routines.length,
                      itemBuilder: (_, i) => _RoutineImportCard(
                        routine: _routines[i],
                        onToggle: () => setState(() {
                          _routines[i].selected = !_routines[i].selected;
                        }),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineImportCard extends StatelessWidget {
  final _ParsedRoutine routine;
  final VoidCallback onToggle;

  const _RoutineImportCard({required this.routine, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final matched = routine.matchedCount;
    final total = routine.exercises.length;
    final allMatched = matched == total;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: routine.selected
              ? AppTheme.neonGreen.withAlpha(15)
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: routine.selected
                ? AppTheme.neonGreen.withAlpha(80)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    routine.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  routine.selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: routine.selected ? AppTheme.neonGreen : Colors.grey,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  allMatched ? Icons.check_circle_outline : Icons.warning_amber,
                  size: 14,
                  color: allMatched ? AppTheme.neonGreen : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '$matched/$total ejercicios reconocidos',
                  style: TextStyle(
                    color: allMatched ? Colors.grey : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: routine.exercises.map((ex) {
                final ok = ex.matched != null;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ok
                        ? const Color(0xFF2A3A2A)
                        : const Color(0xFF3A2A2A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${ex.csvName} × ${ex.sets}',
                    style: TextStyle(
                      color: ok ? Colors.white70 : Colors.red[300],
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
