enum AnalyticsPeriod { oneMonth, threeMonths, sixMonths, oneYear, all }

extension AnalyticsPeriodExtension on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.oneMonth:
        return '1M';
      case AnalyticsPeriod.threeMonths:
        return '3M';
      case AnalyticsPeriod.sixMonths:
        return '6M';
      case AnalyticsPeriod.oneYear:
        return '1A';
      case AnalyticsPeriod.all:
        return 'Todo';
    }
  }

  ({DateTime from, DateTime to}) dateRange() {
    final now = DateTime.now();
    final to = now;
    
    switch (this) {
      case AnalyticsPeriod.oneMonth:
        return (from: now.subtract(const Duration(days: 30)), to: to);
      case AnalyticsPeriod.threeMonths:
        return (from: now.subtract(const Duration(days: 90)), to: to);
      case AnalyticsPeriod.sixMonths:
        return (from: now.subtract(const Duration(days: 180)), to: to);
      case AnalyticsPeriod.oneYear:
        return (from: now.subtract(const Duration(days: 365)), to: to);
      case AnalyticsPeriod.all:
        return (from: DateTime(2020, 1, 1), to: to);
    }
  }
}
