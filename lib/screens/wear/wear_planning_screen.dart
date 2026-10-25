import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../widgets/platform/watch_widgets.dart';

class WearPlanningScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const WearPlanningScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['todayPlanningTitle'] as String? ?? '';
    final count = data['todayExercisesCount'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            color: context.palette.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          if (title.isEmpty)
            const Text(
              'Pas de séance\naujourd\'hui',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            )
          else ...[
            WatchHeader(title: title),
            const SizedBox(height: 4),
            WatchStatCard(
              icon: Icons.repeat,
              title: 'Exercices',
              value: '$count',
              color: context.palette.primary,
            ),
          ],
        ],
      ),
    );
  }
}
