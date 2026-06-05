import 'package:flutter/material.dart';

import '../../../tasks/presentation/providers/providers.dart';

class TaskStatsCards extends StatelessWidget {
  final TaskStats stats;

  const TaskStatsCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final spacing = 8.0;
        final childWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _StatCard(
              width: childWidth,
              label: 'Total',
              value: '${stats.total}',
            ),
            _StatCard(
              width: childWidth,
              label: 'Completed',
              value: '${stats.completed}',
            ),
            _StatCard(
              width: childWidth,
              label: 'Pending',
              value: '${stats.pending}',
            ),
            _StatCard(
              width: childWidth,
              label: 'Overdue',
              value: '${stats.overdue}',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
