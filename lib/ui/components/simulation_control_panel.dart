import 'package:flutter/material.dart';

/// シミュレーション操作パネル（スタート/ストップ/リセット）
class SimulationControlPanel extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const SimulationControlPanel({
    super.key,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'シミュレーション操作',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isRunning ? null : onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('スタート'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: isRunning ? onStop : null,
              icon: const Icon(Icons.stop),
              label: const Text('ストップ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('リセット'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
