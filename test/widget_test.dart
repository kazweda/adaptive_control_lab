// UIの基本的なウィジェットテスト

import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_control_lab/main.dart';

void main() {
  testWidgets('メイン画面の基本要素が表示される', (WidgetTester tester) async {
    // アプリを起動
    await tester.pumpWidget(const MyApp());

    // タイトルの確認
    expect(find.text('制御系シミュレーション'), findsOneWidget);

    // 制御ボタンの確認
    expect(find.text('スタート'), findsOneWidget);
    expect(find.text('ストップ'), findsOneWidget);
    expect(find.text('リセット'), findsOneWidget);

    // ステータス表示の確認
    expect(find.text('状態：'), findsOneWidget);
    expect(find.text('停止中'), findsOneWidget);
  });

  testWidgets('スタートボタンで状態が変更される', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 初期状態は停止中
    expect(find.text('停止中'), findsOneWidget);

    // スタートボタンをタップ
    await tester.tap(find.text('スタート'));
    await tester.pumpAndSettle();

    // 実行中に変更される
    expect(find.text('実行中'), findsOneWidget);
  });

  testWidgets('目標値・PIDゲイン・プラントパラメータのUIが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 各セクションの確認
    expect(find.text('目標値'), findsOneWidget);
    expect(find.text('PID ゲイン調整'), findsOneWidget);
    expect(find.text('プラント設定（自動制御される対象）'), findsOneWidget);
  });
}
