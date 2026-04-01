import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../utils/deterministic_message_generator.dart';

/// Displays a trend badge with a deterministic motivational message.
/// [status]: NEW | OVERLOAD | STAGNANT | REGRESSION
/// [seed]: opaque string from the backend used to pick a consistent message
class InsightBadge extends StatelessWidget {
  final String status;
  final String seed;

  const InsightBadge({super.key, required this.status, required this.seed});

  static const _configs = <String, _BadgeConfig>{
    'OVERLOAD':   _BadgeConfig(Icons.trending_up,    AppTheme.neonGreen),
    'STAGNANT':   _BadgeConfig(Icons.trending_flat,  Color(0xFFFFB74D)),
    'REGRESSION': _BadgeConfig(Icons.trending_down,  Colors.redAccent),
    'NEW':        _BadgeConfig(Icons.fiber_new,       Colors.white38),
  };

  @override
  Widget build(BuildContext context) {
    final config = _configs[status] ?? _configs['NEW']!;
    final message = DeterministicMessageGenerator.generate(seed, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: config.color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeConfig {
  final IconData icon;
  final Color color;
  const _BadgeConfig(this.icon, this.color);
}
