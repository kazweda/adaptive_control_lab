import 'package:flutter/material.dart';
import '../../simulation/simulator.dart';

/// PID制御器の設定画面
class PIDControllerScreen extends StatefulWidget {
  final Simulator simulator;
  final VoidCallback onUpdate;

  const PIDControllerScreen({
    super.key,
    required this.simulator,
    required this.onUpdate,
  });

  @override
  State<PIDControllerScreen> createState() => _PIDControllerScreenState();
}

class _PIDControllerScreenState extends State<PIDControllerScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildPIDGainsSection()],
      ),
    );
  }

  /// PIDゲイン調整セクション
  Widget _buildPIDGainsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PID ゲイン調整',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Kp（比例ゲイン）
            _buildGainSlider(
              label: 'Kp（比例）',
              value: widget.simulator.pidKp,
              onChanged: (value) {
                widget.simulator.pidKp = value;
                widget.onUpdate();
              },
              description: '素早く反応する程度',
            ),
            const SizedBox(height: 16),

            // Ki（積分ゲイン）
            _buildGainSlider(
              label: 'Ki（積分）',
              value: widget.simulator.pidKi,
              onChanged: (value) {
                widget.simulator.pidKi = value;
                widget.onUpdate();
              },
              description: 'ズレを直す強さ',
            ),
            const SizedBox(height: 16),

            // Kd（微分ゲイン）
            _buildGainSlider(
              label: 'Kd（微分）',
              value: widget.simulator.pidKd,
              onChanged: (value) {
                widget.simulator.pidKd = value;
                widget.onUpdate();
              },
              description: '揺れを抑える程度',
            ),
          ],
        ),
      ),
    );
  }

  /// ゲインスライダーのヘルパーウィジェット
  Widget _buildGainSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              value.toStringAsFixed(3),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
