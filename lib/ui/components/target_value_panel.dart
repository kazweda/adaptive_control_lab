import 'package:flutter/material.dart';
import '../../simulation/simulator.dart';

/// 目標値表示パネル（値は 1 に固定）
class TargetValuePanel extends StatelessWidget {
  final Simulator simulator;

  const TargetValuePanel({super.key, required this.simulator});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '目標値',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              simulator.targetValue.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
