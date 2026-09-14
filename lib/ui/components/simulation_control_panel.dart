import 'package:flutter/material.dart';
import 'controller_selector_panel.dart';

/// 操作パネル（スタート/ストップ/リセット、PID/STR切り替え）
class SimulationControlPanel extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final int selectedControllerIndex;
  final ValueChanged<int> onControllerChanged;

  const SimulationControlPanel({
    super.key,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.selectedControllerIndex,
    required this.onControllerChanged,
  });

  // ウィンドウ幅が広い場合にボタンが間延びしすぎないようにする上限幅
  static const double _maxButtonWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '操作パネル',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxButtonWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isRunning ? null : onStart,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('スタート'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: isRunning ? onStop : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('ストップ'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('リセット'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxButtonWidth),
                child: SizedBox(
                  width: double.infinity,
                  child: ControllerSelectorPanel(
                    selectedControllerIndex: selectedControllerIndex,
                    onChanged: onControllerChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
