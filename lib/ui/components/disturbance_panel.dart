import 'package:flutter/material.dart';
import '../../control/disturbance.dart';
import '../../simulation/simulator.dart';

/// 外乱設定パネル
class DisturbancePanel extends StatelessWidget {
  final Simulator simulator;
  final ValueChanged<DisturbanceType> onTypeChanged;
  final ValueChanged<String> onPresetApplied;

  const DisturbancePanel({
    super.key,
    required this.simulator,
    required this.onTypeChanged,
    required this.onPresetApplied,
  });

  @override
  Widget build(BuildContext context) {
    final presets = Simulator.getAvailablePresets();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '外乱設定',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // 外乱タイプドロップダウン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '外乱タイプ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<DisturbanceType>(
                  value: simulator.disturbanceType,
                  items: const [
                    DropdownMenuItem(
                      value: DisturbanceType.none,
                      child: Text('なし'),
                    ),
                    DropdownMenuItem(
                      value: DisturbanceType.step,
                      child: Text('ステップ'),
                    ),
                    DropdownMenuItem(
                      value: DisturbanceType.impulse,
                      child: Text('インパルス'),
                    ),
                    DropdownMenuItem(
                      value: DisturbanceType.sinusoid,
                      child: Text('正弦波'),
                    ),
                    DropdownMenuItem(
                      value: DisturbanceType.noise,
                      child: Text('雑音'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    onTypeChanged(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 現在のプリセット表示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'プリセット',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    simulator.currentPresetName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // プリセットボタングリッド
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                final isActive =
                    simulator.currentPresetName == preset.displayName;
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
                    onPresetApplied(preset.name);
                  },
                  child: Text(
                    preset.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
