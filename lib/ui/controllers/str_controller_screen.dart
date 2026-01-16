import 'package:flutter/material.dart';
import '../../simulation/simulator.dart';

/// STR制御器の設定画面（プレースホルダー）
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'STR制御器設定画面\n（今後実装予定）',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
