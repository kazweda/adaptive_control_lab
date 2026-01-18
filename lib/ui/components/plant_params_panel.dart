import 'package:flutter/material.dart';
import '../../simulation/simulator.dart';

/// プラント設定パネル
class PlantParamsPanel extends StatelessWidget {
  final Simulator simulator;
  final ValueChanged<bool> onPlantOrderChanged;
  final ValueChanged<double> onParamAChanged;
  final ValueChanged<double> onParamBChanged;
  final ValueChanged<double> onParamA1Changed;
  final ValueChanged<double> onParamA2Changed;
  final ValueChanged<double> onParamB1Changed;
  final ValueChanged<double> onParamB2Changed;

  const PlantParamsPanel({
    super.key,
    required this.simulator,
    required this.onPlantOrderChanged,
    required this.onParamAChanged,
    required this.onParamBChanged,
    required this.onParamA1Changed,
    required this.onParamA2Changed,
    required this.onParamB1Changed,
    required this.onParamB2Changed,
  });

  Widget _buildPlantParamSlider({
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'プラント設定（自動制御される対象）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // プラント次数切替
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'プラント次数',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<bool>(
                  value: simulator.isSecondOrderPlant,
                  items: const [
                    DropdownMenuItem<bool>(value: false, child: Text('1次')),
                    DropdownMenuItem<bool>(value: true, child: Text('2次')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    onPlantOrderChanged(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!simulator.isSecondOrderPlant) ...[
              // 1次系: a, b
              _buildPlantParamSlider(
                label: '慣性の強さ (a)',
                value: simulator.plantParamA,
                onChanged: onParamAChanged,
                description: '大きいほど前の値が強く影響',
              ),
              const SizedBox(height: 16),
              _buildPlantParamSlider(
                label: '応答の敏感さ (b)',
                value: simulator.plantParamB,
                onChanged: onParamBChanged,
                description: '大きいほど入力に敏感に反応',
              ),
            ] else ...[
              // 2次系: a1, a2, b1, b2
              _buildPlantParamSlider(
                label: 'フィードバック係数 (a1)',
                value: simulator.plantParamA1,
                onChanged: onParamA1Changed,
                description: 'y(k-1) の係数',
              ),
              const SizedBox(height: 16),
              _buildPlantParamSlider(
                label: 'フィードバック係数 (a2)',
                value: simulator.plantParamA2,
                onChanged: onParamA2Changed,
                description: 'y(k-2) の係数',
              ),
              const SizedBox(height: 16),
              _buildPlantParamSlider(
                label: '入力係数 (b1)',
                value: simulator.plantParamB1,
                onChanged: onParamB1Changed,
                description: 'u(k-1) の係数',
              ),
              const SizedBox(height: 16),
              _buildPlantParamSlider(
                label: '入力係数 (b2)',
                value: simulator.plantParamB2,
                onChanged: onParamB2Changed,
                description: 'u(k-2) の係数',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
