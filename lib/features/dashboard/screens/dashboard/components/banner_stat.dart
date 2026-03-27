import 'package:flutter/material.dart';

class BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const BannerStat({
    required this.label,
    required this.value,
    required this.isDark,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isDark
                ? colorScheme.onSurfaceVariant
                : colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
