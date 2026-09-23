// UIの基本的なウィジェットテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:adaptive_control_lab/main.dart';

void main() {
  testWidgets('メイン画面の基本要素が表示される', (WidgetTester tester) async {
    // テスト用の画面サイズを設定（デフォルト800x600では小さいため）
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    // アプリを起動
    await tester.pumpWidget(const MyApp());

    // テスト終了時にリセット
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
    // テスト用の画面サイズを設定
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MyApp());

    // テスト終了時にリセット
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 初期状態は停止中
    expect(find.text('停止中'), findsOneWidget);

    // スタートボタンをタップ
    await tester.tap(find.text('スタート'));
    await tester.pump(); // pumpAndSettleではなくpumpを使用（Timerが動き続けるため）

    // 実行中に変更される
    expect(find.text('実行中'), findsOneWidget);
  });

  testWidgets('PIDゲイン・プラントパラメータのUIが表示される', (WidgetTester tester) async {
    // テスト用の画面サイズを設定
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MyApp());

    // テスト終了時にリセット
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 各セクションの確認
    expect(find.text('PID ゲイン調整'), findsOneWidget);
    expect(find.text('プラント設定（制御対象）'), findsOneWidget);

    // 目標値は状態カードに固定値として表示される（設定用スライダーは削除済み）
    expect(find.text('目標値：'), findsOneWidget);
  });

  testWidgets('表示ウィンドウの選択肢と切り替えができる', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MyApp());

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 初期選択は「標準」(200)
    final segmentedButton = find.byKey(const Key('chartWindowSegmentedButton'));
    expect(segmentedButton, findsOneWidget);
    expect(tester.widget<SegmentedButton<int>>(segmentedButton).selected, {
      200,
    });

    // 「全体」(501)をワンタップで選択
    await tester.tap(
      find.descendant(of: segmentedButton, matching: find.text('全体')),
    );
    await tester.pump();
    expect(tester.widget<SegmentedButton<int>>(segmentedButton).selected, {
      501,
    });

    // 「標準」(200)にワンタップで戻せる
    await tester.tap(
      find.descendant(of: segmentedButton, matching: find.text('標準')),
    );
    await tester.pump();
    expect(tester.widget<SegmentedButton<int>>(segmentedButton).selected, {
      200,
    });
  });

  testWidgets('コントローラー選択タブでPID/STRの有効表示が切り替わる', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MyApp());

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Opacity opacityAncestor(Finder textFinder) => tester.widget<Opacity>(
      find.ancestor(of: textFinder, matching: find.byType(Opacity)).first,
    );

    // PIDとSTRのセグメントボタン（操作パネル内に組み込み）が表示される
    expect(find.text('PID制御'), findsOneWidget);
    expect(find.text('STR制御'), findsOneWidget);

    // PID/STR両方のカードが常時マウントされている
    expect(find.text('PID ゲイン調整'), findsOneWidget);
    expect(find.text('応答特性の調整'), findsOneWidget);

    // 初期状態ではPIDが選択されているため、STR側がグレーアウトされている
    expect(opacityAncestor(find.text('応答特性の調整')).opacity, lessThan(1.0));

    // STRタブをタップ
    await tester.tap(find.text('STR制御'));
    await tester.pump();

    // 両方のカードは引き続き表示され、今度はPID側がグレーアウトされる
    expect(find.text('PID ゲイン調整'), findsOneWidget);
    expect(find.text('応答特性の調整'), findsOneWidget);
    expect(opacityAncestor(find.text('PID ゲイン調整')).opacity, lessThan(1.0));

    // PIDタブに戻す
    await tester.tap(find.text('PID制御'));
    await tester.pump();

    // PID側のグレーアウトが解除される
    expect(find.text('PID ゲイン調整'), findsOneWidget);
    expect(opacityAncestor(find.text('応答特性の調整')).opacity, lessThan(1.0));
  });

  testWidgets('AppBar にバージョンが表示され、PackageInfo 取得後に更新される', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    PackageInfo.setMockInitialValues(
      appName: 'adaptive_control_lab',
      packageName: 'com.example.adaptive_control_lab',
      version: '2.3.4',
      buildNumber: '9',
      buildSignature: 'mock',
      installerStore: 'mock',
    );

    await tester.pumpWidget(const MyApp());

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 初期フォールバック値が表示される
    expect(find.text('v1.0.0+1'), findsOneWidget);

    // 非同期取得後の値に更新される
    await tester.pumpAndSettle();
    expect(find.text('v2.3.4+9'), findsOneWidget);
  });
}
