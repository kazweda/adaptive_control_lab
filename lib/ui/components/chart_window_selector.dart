import 'package:flutter/material.dart';

/// チャート表示ウィンドウ選択パネル
class ChartWindowSelector extends StatelessWidget {
  final int? chartWindow;
  final ValueChanged<int?> onChanged;

  const ChartWindowSelector({
    super.key,
    required this.chartWindow,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [200, 500, 1000, null];
    String labelOf(int? v) => v == null ? '全履歴' : v.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '表示ウィンドウ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        DropdownButton<int?>(
          value: chartWindow,
          items: options
              .map(
                (v) =>
                    DropdownMenuItem<int?>(value: v, child: Text(labelOf(v))),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
