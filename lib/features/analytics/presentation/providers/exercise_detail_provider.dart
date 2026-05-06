import 'package:flutter/material.dart';

import '../../data/models/analytics_models.dart';
import '../../domain/analytics_period.dart';
import '../../domain/analytics_repository.dart';

class ExerciseDetailProvider extends ChangeNotifier {
  final IAnalyticsRepository _repository;

  List<Progression1RMModel> _allData = [];
  List<Progression1RMModel> _filteredData = [];
  AnalyticsPeriod _period = AnalyticsPeriod.all;
  bool _isLoading = true;
  String? _error;

  ExerciseDetailProvider({required IAnalyticsRepository repository})
    : _repository = repository;

  List<Progression1RMModel> get allData => _allData;
  List<Progression1RMModel> get filteredData => _filteredData;
  AnalyticsPeriod get period => _period;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get best1Rm {
    if (_filteredData.isEmpty) return 0.0;
    return _filteredData
        .map((e) => e.estimated1Rm)
        .reduce((a, b) => a > b ? a : b);
  }

  int get totalEntries => _filteredData.length;

  Future<void> loadProgression(int exerciseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.get1RMProgression(exerciseId);
      _allData = data;
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo cargar la progresión.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void changePeriod(AnalyticsPeriod period) {
    if (_period == period) return;
    _period = period;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_period == AnalyticsPeriod.all) {
      _filteredData = List.unmodifiable(_allData);
      return;
    }

    final range = _period.dateRange();
    _filteredData = List.unmodifiable(
      _allData.where((d) => !d.date.isBefore(range.from)).toList(),
    );
  }
}
