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
  // 操作パネルのボタンに合わせたプリセットボタンの幅制約
  static const double _minButtonWidth = 88.0;
  static const double _maxButtonWidth = 140.0;

  // カード間の高さを揃えるための最小高さ（他の設定カードとの見た目のバランス用）
  static const double _presetCardMinHeight = 170.0;
  static const double _detailCardMinHeight = 260.0;

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _presetCardMinHeight),
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
            ],
          ),
        ),
      ),
    );
  }

  /// 詳細設定カード（ゲインを個別に調整）
  Widget _buildDetailCard() {
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _detailCardMinHeight),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PID 詳細設定（個別に調整）',
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
                max: 1.5,
              ),
              const SizedBox(height: 8),

              // Ki（積分ゲイン）
              _buildGainSlider(
                label: 'Ki（積分）',
                value: widget.simulator.pidKi,
                onChanged: (value) {
                  widget.simulator.pidKi = value;
                  widget.onUpdate();
                },
                max: 1.0,
              ),
              const SizedBox(height: 8),

              // Kd（微分ゲイン）
              _buildGainSlider(
                label: 'Kd（微分）',
                value: widget.simulator.pidKd,
                onChanged: (value) {
                  widget.simulator.pidKd = value;
                  widget.onUpdate();
                },
                max: 1.0,
              ),
            ],
          ),
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
            return ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: _minButtonWidth,
                maxWidth: _maxButtonWidth,
              ),
              child: ElevatedButton(
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
                child: Text(
                  preset.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// ゲインスライダーのヘルパーウィジェット
  /// （各ゲインの意味はWiki「PID Tuning Guide」を参照）
  Widget _buildGainSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
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
