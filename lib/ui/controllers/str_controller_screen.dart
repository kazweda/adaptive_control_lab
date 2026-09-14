import 'package:flutter/material.dart';
import '../../simulation/simulator.dart';

/// STR制御器の設定画面
class STRControllerScreen extends StatefulWidget {
  final Simulator simulator;
  final VoidCallback onUpdate;

  const STRControllerScreen({
    super.key,
    required this.simulator,
    required this.onUpdate,
  });

  @override
  State<STRControllerScreen> createState() => _STRControllerScreenState();
}

class _STRControllerScreenState extends State<STRControllerScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPresetCard(),
        const SizedBox(height: 16),
        _buildDetailCard(),
      ],
    );
  }

  /// プリセット選択カード
  Widget _buildPresetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '応答特性の調整',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPresetSelector(),
          ],
        ),
      ),
    );
  }

  /// 詳細設定カード（極を個別に調整）
  Widget _buildDetailCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '詳細設定（極を個別に調整）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 1次・2次共通: targetPole1
            _buildPoleSlider(
              label: '主極（極1）',
              value: widget.simulator.strTargetPole1,
              onChanged: (value) {
                widget.simulator.setStrTargetPoles(
                  value,
                  widget.simulator.strTargetPole2,
                );
                widget.onUpdate();
              },
              description: '小さいほど速く減衰（0 < p < 1）',
            ),
            const SizedBox(height: 16),

            // 2次系のみ表示
            if (widget.simulator.isSecondOrderPlant)
              Column(
                children: [
                  _buildPoleSlider(
                    label: '補助極（極2）',
                    value: widget.simulator.strTargetPole2,
                    onChanged: (value) {
                      widget.simulator.setStrTargetPoles(
                        widget.simulator.strTargetPole1,
                        value,
                      );
                      widget.onUpdate();
                    },
                    description: '2次プラント用の補助極',
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Butterworth配置ボタン（2次系のみ）
            if (widget.simulator.isSecondOrderPlant)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    widget.simulator.str?.setTargetPolesButterworth(0.3);
                    // STR オブジェクトの極を Simulator のプロパティに同期
                    if (widget.simulator.str != null) {
                      widget.simulator.setStrTargetPoles(
                        widget.simulator.str!.targetPole1,
                        widget.simulator.str!.targetPole2,
                      );
                    }
                    widget.onUpdate();
                  });
                },
                icon: const Icon(Icons.tune),
                label: const Text('Butterworth配置（推奨）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[300],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// プリセット選択UI
  Widget _buildPresetSelector() {
    final presets = Simulator.getAvailableStrPresets();
    final currentName = widget.simulator.currentStrPresetName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'プリセット',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                currentName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            final isActive = currentName == preset.displayName;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.blue : Colors.grey[300],
                foregroundColor: isActive ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                setState(() {
                  widget.simulator.applyStrPreset(preset.name);
                  widget.onUpdate();
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preset.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    preset.description,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// 極スライダーのヘルパーウィジェット
  Widget _buildPoleSlider({
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
          min: 0.01,
          max: 0.99,
          divisions: 98,
          onChanged: (v) {
            setState(() {
              onChanged(v);
            });
          },
        ),
      ],
    );
  }
}
