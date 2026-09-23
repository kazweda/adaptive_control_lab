import 'package:flutter/material.dart';

/// チャート表示ズームレベル切替（標準200ステップ / 全体501ステップをワンタップで切替）
///
/// 「全体」はSimulatorのmaxSteps(500)+1（初期状態k=0を含む履歴の最大長）に合わせている。
class ChartWindowSelector extends StatelessWidget {
  static const int standardWindow = 200;
  static const int fullWindow = 501;

  final int chartWindow;
  final ValueChanged<int> onChanged;

  const ChartWindowSelector({
    super.key,
    required this.chartWindow,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      key: const Key('chartWindowSegmentedButton'),
      segments: const [
        ButtonSegment(value: standardWindow, label: Text('標準')),
        ButtonSegment(value: fullWindow, label: Text('全体')),
      ],
      selected: {chartWindow},
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelectionChanged: (selected) => onChanged(selected.first),
    );
  }
}
