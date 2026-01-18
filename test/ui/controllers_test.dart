// コントローラー画面のウィジェットテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_control_lab/simulation/simulator.dart';
import 'package:adaptive_control_lab/ui/controllers/pid_controller_screen.dart';
import 'package:adaptive_control_lab/ui/controllers/str_controller_screen.dart';

void main() {
  group('PIDControllerScreen', () {
    late Simulator simulator;

    setUp(() {
      simulator = Simulator();
    });

    testWidgets('PIDゲイン調整セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PIDControllerScreen(simulator: simulator, onUpdate: () {}),
          ),
        ),
      );

      // PIDゲイン調整のタイトルが表示される
      expect(find.text('PID ゲイン調整'), findsOneWidget);

      // 各ゲインのラベルが表示される
      expect(find.text('Kp（比例）'), findsOneWidget);
      expect(find.text('Ki（積分）'), findsOneWidget);
      expect(find.text('Kd（微分）'), findsOneWidget);

      // 説明文が表示される
      expect(find.text('素早く反応する程度'), findsOneWidget);
      expect(find.text('ズレを直す強さ'), findsOneWidget);
      expect(find.text('揺れを抑える程度'), findsOneWidget);

      // スライダーが3つ表示される
      expect(find.byType(Slider), findsNWidgets(3));
    });

    testWidgets('スライダー操作でSimulatorの値が更新される', (WidgetTester tester) async {
      bool updateCalled = false;
      final initialKp = simulator.pidKp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PIDControllerScreen(
              simulator: simulator,
              onUpdate: () {
                updateCalled = true;
              },
            ),
          ),
        ),
      );

      // Kpスライダーを操作（最初のSlider）
      await tester.drag(find.byType(Slider).first, const Offset(100, 0));
      await tester.pump();

      // onUpdateが呼ばれたことを確認
      expect(updateCalled, true);

      // Simulatorの値が変更されている（初期値と異なる）
      expect(simulator.pidKp, isNot(equals(initialKp)));
    });

    testWidgets('初期値が正しく表示される', (WidgetTester tester) async {
      // Simulatorの初期値を取得
      final initialKp = simulator.pidKp;
      final initialKi = simulator.pidKi;
      final initialKd = simulator.pidKd;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PIDControllerScreen(simulator: simulator, onUpdate: () {}),
          ),
        ),
      );

      // 初期値のテキストが表示される（各ゲインで2箇所ずつ表示される：ラベル横と説明下）
      expect(find.text(initialKp.toStringAsFixed(3)), findsAtLeast(1));
      expect(find.text(initialKi.toStringAsFixed(3)), findsAtLeast(1));
      expect(find.text(initialKd.toStringAsFixed(3)), findsAtLeast(1));
    });
  });

  group('STRControllerScreen', () {
    late Simulator simulator;

    setUp(() {
      simulator = Simulator();
    });

    testWidgets('STR有効化トグルが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: STRControllerScreen(simulator: simulator, onUpdate: () {}),
          ),
        ),
      );

      // STR制御器トグルテキストが表示される
      expect(find.text('STR制御器'), findsOneWidget);
      // Switchが表示されている
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('STR有効時に極スライダーが表示される', (WidgetTester tester) async {
      simulator.setStrEnabled(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: STRControllerScreen(simulator: simulator, onUpdate: () {}),
          ),
        ),
      );

      // 主極スライダーラベルが表示される
      expect(find.text('主極（極1）'), findsOneWidget);
    });
  });
}
