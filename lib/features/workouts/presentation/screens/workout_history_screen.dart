import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/workout_card.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<dynamic> _workouts = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  /// True cuando los datos son del cache y estamos refrescando en background.
  bool _isUsingStaleData = false;

  String? _errorMessage;

  /// Chip seleccionado actualmente. 'all' = All Workouts, 'routines' = Routines
  String _selectedChip = 'all';

  @override
  void initState() {
    super.initState();
    _loadWithCache();
  }

  /// Fetch que sigue el patrón SWR: muestra cache primero, refresca en background.
  Future<void> _loadWithCache() async {
    final hadData = _hasLoadedOnce;

    // Si ya tenemos datos, NO spinner — los mantenemos visibles mientras revalidamos
    if (hadData) {
      setState(() {
        _errorMessage = null;
        _isUsingStaleData = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    // 1. Intentar cache primero — mostrar aunque esté stale
    final cached = await CacheManager.getCache('workouts');
    if (cached != null && mounted) {
      final cachedList = cached is List ? cached : [];
      if (!hadData) {
        setState(() {
          _workouts = cachedList;
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      } else {
        _workouts = cachedList;
      }
    }

    // 2. Fetch en background para datos frescos
    try {
      final response = await ApiClient.get(
        '/api/workouts',
        queryParams: {'page': '0', 'size': '20'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final freshList = data['content'] ?? [];

        if (mounted) {
          setState(() {
            _workouts = freshList;
            _isLoading = false;
            _isUsingStaleData = false;
            _hasLoadedOnce = true;
            _errorMessage = null;
          });
          await CacheManager.setCache('workouts', freshList);
        }
      } else {
        _handleFetchError(null);
      }
    } catch (e) {
      _handleFetchError(e);
    }
  }

  void _handleFetchError(dynamic e) {
    if (!mounted) return;

    if (_hasLoadedOnce) {
      // Ya tenemos datos — seguir mostrándolos con aviso sutil
      setState(() {
        _isUsingStaleData = true;
        _isLoading = false;
      });
    } else if (_workouts.isEmpty) {
      // Primera carga y sin cache — mostrar error
      setState(() {
        _errorMessage =
            '❌ Error de conexión: Verifica que el backend esté encendido y en la misma WiFi.\n($e)';
        _isLoading = false;
      });
    }
  }

  /// Pull-to-refresh: limpia cache y carga fresco.
  Future<void> _fetchWorkouts() async {
    await CacheManager.clearCache('workouts');
    _hasLoadedOnce = false;
    await _loadWithCache();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initial = (user?.email?.isNotEmpty == true)
        ? user!.email![0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonGreen),
            onPressed: _fetchWorkouts,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.neonGreen,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros (Chips horizontales)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildChip('All Workouts', 'all'),
                const SizedBox(width: 8),
                _buildChip('Routines', 'routines'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Indicador de refresh en background (usando cache mientras revalida)
          if (_isUsingStaleData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.1),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Actualizando…',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          // Lista de Entrenamientos o Error
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonGreen),
                  )
                : _errorMessage != null && !_isUsingStaleData
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 64,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchWorkouts,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _workouts.isEmpty
                ? const Center(
                    child: Text('No hay entrenamientos. ¡Importa tu CSV!'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      final workout = _workouts[index];
                      return WorkoutCard(
                        workout: workout,
                        onDeleted: () => setState(() {
                          _workouts.removeWhere(
                            (w) => w['id'] == workout['id'],
                          );
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String chipId) {
    final isSelected = _selectedChip == chipId;
    return GestureDetector(
      onTap: () {
        if (chipId == 'routines') {
          context.push('/routines');
        } else {
          setState(() => _selectedChip = chipId);
        }
      },
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected
            ? AppTheme.neonGreen
            : AppTheme.cardBackground,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
