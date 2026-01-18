import 'package:flutter/material.dart';

/// コントローラー選択パネル（PID / STR）
class ControllerSelectorPanel extends StatelessWidget {
  final int selectedControllerIndex;
  final ValueChanged<int> onChanged;

  const ControllerSelectorPanel({
    super.key,
    required this.selectedControllerIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment<int>(
          value: 0,
          label: Text('PID制御'),
          icon: Icon(Icons.tune),
        ),
        ButtonSegment<int>(
          value: 1,
          label: Text('STR制御'),
          icon: Icon(Icons.auto_graph),
        ),
      ],
      selected: {selectedControllerIndex},
      onSelectionChanged: (Set<int> newSelection) {
        onChanged(newSelection.first);
      },
    );
  }
}
