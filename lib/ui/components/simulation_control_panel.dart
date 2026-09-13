import 'package:flutter/material.dart';

/// シミュレーション制御ボタンパネル（スタート/ストップ/リセット）
class SimulationControlPanel extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  // ボタンの並び方向（横並び/縦積み）。狭い領域に配置する場合は vertical を指定。
  final Axis direction;

  const SimulationControlPanel({
    super.key,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final startButton = ElevatedButton.icon(
      onPressed: isRunning ? null : onStart,
      icon: const Icon(Icons.play_arrow),
      label: const Text('スタート'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.green,
        disabledBackgroundColor: Colors.grey,
      ),
    );

    final stopButton = ElevatedButton.icon(
      onPressed: isRunning ? onStop : null,
      icon: const Icon(Icons.stop),
      label: const Text('ストップ'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.orange,
        disabledBackgroundColor: Colors.grey,
      ),
    );

    final resetButton = ElevatedButton.icon(
      onPressed: onReset,
      icon: const Icon(Icons.refresh),
      label: const Text('リセット'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.red,
      ),
    );

    if (direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          startButton,
          const SizedBox(height: 8),
          stopButton,
          const SizedBox(height: 8),
          resetButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: startButton),
        const SizedBox(width: 8),
        Expanded(child: stopButton),
        const SizedBox(width: 8),
        Expanded(child: resetButton),
      ],
    );
  }
}
