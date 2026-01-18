import 'package:flutter/material.dart';
import '../../simulation/simulator.dart';

/// シミュレーションステータス表示パネル
class SimulationStatusPanel extends StatelessWidget {
  final Simulator simulator;
  final bool isRunning;

  const SimulationStatusPanel({
    super.key,
    required this.simulator,
    required this.isRunning,
  });

  Widget _buildValueRow(String label, double value, {bool isInteger = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label：', style: const TextStyle(fontSize: 14)),
        Text(
          isInteger ? value.toInt().toString() : value.toStringAsFixed(3),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 実行状態
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '状態：',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isRunning ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isRunning ? '実行中' : '停止中',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 各値の表示
            _buildValueRow('目標値', simulator.targetValue),
            const SizedBox(height: 8),
            _buildValueRow('出力', simulator.plantOutput),
            const SizedBox(height: 8),
            _buildValueRow('制御入力', simulator.controlInput),
            const SizedBox(height: 8),
            _buildValueRow(
              'ステップ',
              simulator.stepCount.toDouble(),
              isInteger: true,
            ),
          ],
        ),
      ),
    );
  }
}
