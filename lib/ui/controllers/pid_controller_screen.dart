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
    return _buildPIDGainsSection();
  }

  /// PIDゲイン調整セクション（プリセット + 詳細設定）
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
            _buildPresetSelector(),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                title: const Text(
                  '詳細設定（個別に調整）',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                children: [
                  // Kp（比例ゲイン）
                  _buildGainSlider(
                    label: 'Kp（比例）',
                    value: widget.simulator.pidKp,
                    onChanged: (value) {
                      widget.simulator.pidKp = value;
                      widget.onUpdate();
                    },
                    description: '素早く反応する程度',
                    max: 1.5,
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
                    max: 1.0,
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
                    max: 1.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// プリセット選択UI
  Widget _buildPresetSelector() {
    final presets = Simulator.getAvailablePidPresets();
    final currentName = widget.simulator.currentPidPresetName;

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
                  widget.simulator.applyPidPreset(preset.name);
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

  /// ゲインスライダーのヘルパーウィジェット
  Widget _buildGainSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required String description,
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
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 0.0,
          max: max,
          divisions: 100,
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
