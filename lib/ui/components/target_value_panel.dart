import 'package:flutter/material.dart';
import '../../simulation/simulator.dart';

/// 目標値調整パネル
class TargetValuePanel extends StatelessWidget {
  final Simulator simulator;
  final ValueChanged<double> onChanged;

  const TargetValuePanel({
    super.key,
    required this.simulator,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '目標値',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: simulator.targetValue,
                    min: 0.0,
                    max: 2.0,
                    divisions: 40,
                    label: simulator.targetValue.toStringAsFixed(2),
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  simulator.targetValue.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
