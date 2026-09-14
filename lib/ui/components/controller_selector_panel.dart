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
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      segments: const [
        ButtonSegment<int>(
          value: 0,
          label: FittedBox(fit: BoxFit.scaleDown, child: Text('PID制御')),
        ),
        ButtonSegment<int>(
          value: 1,
          label: FittedBox(fit: BoxFit.scaleDown, child: Text('STR制御')),
        ),
      ],
      selected: {selectedControllerIndex},
      onSelectionChanged: (Set<int> newSelection) {
        onChanged(newSelection.first);
      },
    );
  }
}
