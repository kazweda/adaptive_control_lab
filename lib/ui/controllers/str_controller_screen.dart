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
      children: [
        _buildSTREnableSection(),
        const SizedBox(height: 16),
        if (widget.simulator.strEnabled) ...[
          _buildTargetPolesSection(),
          const SizedBox(height: 16),
          _buildEstimatedParametersSection(),
        ],
      ],
    );
  }

  /// STR有効化トグルセクション
  Widget _buildSTREnableSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'STR制御器',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: widget.simulator.strEnabled,
                  onChanged: (value) {
                    setState(() {
                      widget.simulator.setStrEnabled(value);
                      widget.onUpdate();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.simulator.strEnabled
                  ? 'STR制御有効（自動パラメータ同定）'
                  : 'STR制御無効（PID制御のみ）',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// 所望の極スライダーセクション
  Widget _buildTargetPolesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '所望の極（応答速度・安定性の調整）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 1次・2次共通: targetPole1
            _buildPoleSlider(
              label: '主極（極1）',
              value: widget.simulator.strTargetPole1,
              onChanged: (value) {
                setState(() {
                  widget.simulator.setStrTargetPoles(
                    value,
                    widget.simulator.strTargetPole2,
                  );
                  widget.onUpdate();
                });
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
                      setState(() {
                        widget.simulator.setStrTargetPoles(
                          widget.simulator.strTargetPole1,
                          value,
                        );
                        widget.onUpdate();
                      });
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
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 推定パラメータ表示セクション
  Widget _buildEstimatedParametersSection() {
    final str = widget.simulator.str;
    if (str == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '推定パラメータ（RLS同定）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (str.parameterCount == 2) ...[
              // 1次系
              _buildParameterRow('a（自己回帰係数）', str.estimatedA),
              const SizedBox(height: 8),
              _buildParameterRow('b（入力係数）', str.estimatedB),
            ] else if (str.parameterCount == 4) ...[
              // 2次系
              _buildParameterRow('a1（y(k-1)の係数）', str.estimatedA1),
              const SizedBox(height: 8),
              _buildParameterRow('a2（y(k-2)の係数）', str.estimatedA2),
              const SizedBox(height: 8),
              _buildParameterRow('b1（u(k-1)の係数）', str.estimatedB1),
              const SizedBox(height: 8),
              _buildParameterRow('b2（u(k-2)の係数）', str.estimatedB2),
            ],
          ],
        ),
      ),
    );
  }

  /// パラメータ行のヘルパーウィジェット
  Widget _buildParameterRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value.toStringAsFixed(4),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
