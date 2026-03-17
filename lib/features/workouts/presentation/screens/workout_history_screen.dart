import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
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
  bool _isUsingCache = false;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  String? _errorMessage;

  Future<void> _fetchWorkouts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUsingCache = false;
    });

    try {
      // Intenta cargar del backend
      final response = await ApiClient.get(
        '/api/workouts',
        queryParams: {'page': '0', 'size': '20'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        if (mounted) {
          setState(() {
            _workouts = data['content'] ?? [];
            _isLoading = false;
          });
          // Guarda en caché para la próxima vez
          await CacheManager.setCache('workouts', _workouts);
        }
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      // Si falla, intenta cargar del caché
      final cachedWorkouts = await CacheManager.getCache('workouts');
      
      if (cachedWorkouts != null) {
        if (mounted) {
          setState(() {
            _workouts = cachedWorkouts is List ? cachedWorkouts : [];
            _isLoading = false;
            _isUsingCache = true;
            _errorMessage = '📱 Mostrando datos guardados (offline). Reconecta para actualizar.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = '❌ Error de conexión: Verifica que el backend esté encendido y en la misma WiFi.\n($e)';
            _isLoading = false;
          });
        }
      }
    }
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
                _buildChip('All Workouts', true),
                const SizedBox(width: 8),
                _buildChip('Templates', false),
                const SizedBox(width: 8),
                _buildChip('Routines', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Indicador de modo offline
          if (_isUsingCache)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.2),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo offline - Datos cacheados',
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
                : _errorMessage != null && !_isUsingCache
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
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
                              return WorkoutCard(workout: workout);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Chip(
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
    );
  }
}
