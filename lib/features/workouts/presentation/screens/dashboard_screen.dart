import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/charts/app_bar_chart.dart';
import '../../../analytics/data/models/analytics_models.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final username = _extractUsername(user?.email);
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: provider.isLoading && !provider.hasLoadedOnce
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.neonGreen),
              )
            : provider.error != null && !provider.hasLoadedOnce
                ? _buildError(provider)
                : RefreshIndicator(
                    color: AppTheme.neonGreen,
                    onRefresh: provider.forceRefresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      children: [
                        _buildHeader(username),
                        const SizedBox(height: 28),
                        _buildKpiRow(provider),
                        const SizedBox(height: 28),
                        _buildWeeklyChart(provider),
                        const SizedBox(height: 28),
                        _buildRecentPRs(provider),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(String username) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $username 👋',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's crush it today.",
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppTheme.neonGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  // ── KPI Row ─────────────────────────────────────────────────────────────────

  Widget _buildKpiRow(AnalyticsProvider provider) {
    final workouts = provider.summary?.sessionCount ?? 0;
    final volume = provider.summary?.totalVolume ?? 0;
    final streak = provider.consistency?.currentStreak ?? 0;

    return Row(
      children: [
        _KpiCard(label: 'WORKOUTS', value: '$workouts'),
        const SizedBox(width: 10),
        _KpiCard(label: 'VOLUME', value: _formatVolume(volume)),
        const SizedBox(width: 10),
        _KpiCard(
          label: 'STREAK',
          value: '${streak}d',
          valueColor: streak > 0 ? AppTheme.neonGreen : null,
        ),
      ],
    );
  }

  // ── Weekly Activity Chart ────────────────────────────────────────────────────

  Widget _buildWeeklyChart(AnalyticsProvider provider) {
    final values = provider.weeklyVolume.map((w) => w.totalVolume).toList();
    final labels = provider.weeklyVolume
        .map((w) => DateFormat('d/M').format(w.weekStart))
        .toList();

    return _SectionCard(
      title: 'Weekly Activity',
      child: SizedBox(
        height: 160,
        child: values.isEmpty
            ? const Center(
                child: Text('Sin datos aún',
                    style: TextStyle(color: AppTheme.textGrey)))
            : AppBarChart(
                values: values,
                labels: labels,
                yFormatter: _formatVolume,
                labelInterval: values.length > 6 ? 2 : 1,
              ),
      ),
    );
  }

  // ── Recent PRs ──────────────────────────────────────────────────────────────

  Widget _buildRecentPRs(AnalyticsProvider provider) {
    final prs = provider.recentPRs.take(3).toList();

    return _SectionCard(
      title: 'Recent PRs',
      trailing: TextButton(
        onPressed: () => context.go('/history'),
        child: const Text('Ver historial',
            style: TextStyle(color: AppTheme.neonGreen, fontSize: 13)),
      ),
      child: prs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Sin récords en los últimos 30 días',
                    style: TextStyle(color: AppTheme.textGrey)),
              ),
            )
          : Column(children: prs.map((pr) => _PrTile(pr: pr)).toList()),
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────────

  Widget _buildError(AnalyticsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('No se pudo cargar el dashboard',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              provider.error ?? '',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => provider.forceRefresh(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: Colors.black),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _extractUsername(String? email) {
    if (email == null || email.isEmpty) return 'atleta';
    return email.split('@').first;
  }

  String _formatVolume(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '${v.toStringAsFixed(0)} kg';
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _KpiCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard(
      {required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PrTile extends StatelessWidget {
  final RecentPrModel pr;

  const _PrTile({required this.pr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emoji_events,
                color: AppTheme.neonGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pr.exerciseName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(
                  DateFormat('d MMM yyyy', 'es').format(pr.date),
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${pr.maxWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    color: AppTheme.neonGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('NEW PR',
                    style: TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
