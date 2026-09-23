import 'package:flutter/material.dart';

/// チャート表示ズームレベル切替（標準200ステップ / 全体500ステップをワンタップで切替）
class ChartWindowSelector extends StatelessWidget {
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
        ButtonSegment(value: 200, label: Text('標準')),
        ButtonSegment(value: 500, label: Text('全体')),
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
