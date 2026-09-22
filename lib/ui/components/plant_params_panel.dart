import 'package:flutter/material.dart';
import '../../simulation/simulator.dart';

/// プラント設定パネル（1次系固定）
class PlantParamsPanel extends StatelessWidget {
  final Simulator simulator;
  final ValueChanged<double> onParamAChanged;
  final ValueChanged<double> onParamBChanged;

  const PlantParamsPanel({
    super.key,
    required this.simulator,
    required this.onParamAChanged,
    required this.onParamBChanged,
  });

  // カード間の高さを揃えるための最小高さ（他の設定カードとの見た目のバランス用）
  static const double _cardMinHeight = 220.0;

  /// スライダーのヘルパーウィジェット
  /// （a・bパラメータの意味はWiki「Plant-Settings-Guide」を参照）
  Widget _buildPlantParamSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double max = 1.0,
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
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _cardMinHeight),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'プラント設定（制御対象）',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPlantParamSlider(
                label: '慣性の強さ (a)',
                value: simulator.plantParamA,
                onChanged: onParamAChanged,
              ),
              const SizedBox(height: 8),
              _buildPlantParamSlider(
                label: '応答の敏感さ (b)',
                value: simulator.plantParamB,
                onChanged: onParamBChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
