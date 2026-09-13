// チャートタブカードのウィジェットテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_control_lab/ui/components/charts_tab_card.dart';

void main() {
  Widget buildTestWidget({List<double>? residual}) {
    return MaterialApp(
      home: Scaffold(
        body: ChartsTabCard(
          historyTarget: [0.0, 0.5, 1.0],
          historyOutput: [0.0, 0.3, 0.8],
          historyControl: [0.0, 0.2, 0.4],
          historyResidual: residual ?? [],
          maxDataPoints: 200,
          isRunning: false,
          scrollPosition: 0.0,
          isSecondOrderPlant: false,
          estA: const [],
          estB: const [],
          estA1: const [],
          estA2: const [],
          estB1: const [],
          estB2: const [],
          actualA: const [],
          actualB: const [],
          actualA1: const [],
          actualA2: const [],
          actualB1: const [],
          actualB2: const [],
        ),
      ),
    );
  }

  testWidgets('3つのタブが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('時系列'), findsOneWidget);
    expect(find.text('残差'), findsOneWidget);
    expect(find.text('推定パラメータ'), findsOneWidget);
  });

  testWidgets('初期表示は時系列タブで凡例が見える', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('目標値'), findsOneWidget);
    expect(find.text('出力'), findsOneWidget);
  });

  testWidgets('残差タブに切り替えると残差チャートが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(residual: [0.1, -0.05, 0.02]));

    await tester.tap(find.text('残差'));
    await tester.pumpAndSettle();

    expect(find.textContaining('残差 e_rls(k)'), findsOneWidget);
  });

  testWidgets('推定パラメータタブに切り替えると空状態メッセージが表示される', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('推定パラメータ'));
    await tester.pumpAndSettle();

    expect(find.text('推定パラメータトレース'), findsOneWidget);
  });
}
