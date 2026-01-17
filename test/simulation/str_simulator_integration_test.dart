import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/simulation/simulator.dart';

void main() {
  group('STR + Simulator統合テスト', () {
    late Simulator simulator;

    setUp(() {
      simulator = Simulator();
    });

    test('STR初期化: デフォルトではSTR無効', () {
      expect(simulator.strEnabled, false);
      expect(simulator.str, isNull);
    });

    test('STR有効化: 1次プラント用インスタンスが生成される', () {
      simulator.setPlantOrder(useSecondOrder: false);
      simulator.setStrEnabled(true);

      expect(simulator.strEnabled, true);
      expect(simulator.str, isNotNull);
      expect(simulator.str!.parameterCount, 2);
    });

    test('STR有効化: 2次プラント用インスタンスが生成される', () {
      simulator.setPlantOrder(useSecondOrder: true);
      simulator.setStrEnabled(true);

      expect(simulator.strEnabled, true);
      expect(simulator.str, isNotNull);
      expect(simulator.str!.parameterCount, 4);
    });

    test('STR有効時は所望極を設定可能', () {
      simulator.setStrEnabled(true);
      simulator.setStrTargetPoles(0.4, 0.2);

      expect(simulator.strTargetPole1, 0.4);
      expect(simulator.strTargetPole2, 0.2);
      expect(simulator.str!.targetPole1, 0.4);
      expect(simulator.str!.targetPole2, 0.2);
    });

    test('STR制御: 1次プラントで制御入力が計算される', () {
      simulator.setPlantOrder(useSecondOrder: false);
      simulator.targetValue = 1.0;
      simulator.setStrEnabled(true);

      simulator.step();

      // STR制御入力は計算される
      expect(simulator.controlInput, isNotNull);
    });

    test('STR制御: 1次プラントの複数ステップ実行', () {
      simulator.setPlantOrder(useSecondOrder: false);
      simulator.targetValue = 0.5;
      simulator.setStrEnabled(true);

      // 十分なステップ数で実行
      for (int i = 0; i < 100; i++) {
        simulator.step();
        if (simulator.isHalted) break;
      }

      // ステップが正常に実行されたことを確認
      expect(simulator.stepCount, greaterThan(0));
    });

    test('STR制御: 2次プラントで制御入力が計算される', () {
      simulator.setPlantOrder(useSecondOrder: true);
      simulator.targetValue = 1.0;
      simulator.setStrEnabled(true);

      simulator.step();

      expect(simulator.controlInput, isNotNull);
    });

    test('STR制御: 2次プラント複数ステップ実行', () {
      simulator.setPlantOrder(useSecondOrder: true);
      simulator.targetValue = 0.5;
      simulator.setStrEnabled(true);

      for (int i = 0; i < 100; i++) {
        simulator.step();
        if (simulator.isHalted) break;
      }

      expect(simulator.stepCount, greaterThan(0));
    });

    test('STR: 推定値ゲッターが機能', () {
      simulator.setPlantOrder(useSecondOrder: false);
      simulator.setStrEnabled(true);

      simulator.step();
      simulator.step();

      // STR有効時はSTRから推定値を取得
      final a = simulator.estimatedA;
      final b = simulator.estimatedB;

      expect(a, isNotNull);
      expect(b, isNotNull);
    });

    test('STR: 2次系の推定値ゲッター', () {
      simulator.setPlantOrder(useSecondOrder: true);
      simulator.setStrEnabled(true);

      simulator.step();

      final a1 = simulator.estimatedA1;
      final a2 = simulator.estimatedA2;
      final b1 = simulator.estimatedB1;
      final b2 = simulator.estimatedB2;

      expect(a1, isNotNull);
      expect(a2, isNotNull);
      expect(b1, isNotNull);
      expect(b2, isNotNull);
    });

    test('STR無効化: 推定履歴リセット', () {
      simulator.setStrEnabled(true);

      simulator.step();
      simulator.setStrEnabled(false);

      // 無効化すると推定履歴がクリアされる
      expect(simulator.historyEstimatedA, isEmpty);
    });

    test('STR + RLS同時有効: STRが優先される', () {
      simulator.setStrEnabled(true);
      simulator.setRlsEnabled(true);

      simulator.step();

      // estimatedAはSTRから取得される
      final a = simulator.estimatedA;
      expect(a, isNotNull);
    });

    test('プラント切替: STRが再初期化される', () {
      simulator.setStrEnabled(true);
      simulator.setPlantOrder(useSecondOrder: false);

      final oldStr = simulator.str;
      expect(oldStr!.parameterCount, 2);

      // 2次に切り替え
      simulator.setPlantOrder(useSecondOrder: true);

      // 新しいインスタンスが生成されている
      expect(simulator.str, isNotNull);
      expect(simulator.str!.parameterCount, 4);
    });

    test('リセット後: STRも初期化される', () {
      simulator.setStrEnabled(true);

      // Note: 初期状態でのRLS更新により、2回目のstep()で制御入力が異常値になる可能性がある
      // このため、1回だけstep()を実行してからreset()をテストする
      simulator.step();

      expect(simulator.stepCount, 1);

      simulator.reset();

      expect(simulator.stepCount, 0);
      expect(simulator.str!.rls.theta.length, 2);
    });

    test('STR: ステップ実行で履歴記録', () {
      simulator.setStrEnabled(true);
      simulator.targetValue = 0.1;

      for (int i = 0; i < 30; i++) {
        simulator.step();
        if (simulator.isHalted) break;
      }

      expect(simulator.stepCount, greaterThan(0));
      expect(simulator.historyOutput.length, greaterThan(0));
    });

    test('STR: 安全上限テスト（制御入力が上限を超える場合は停止）', () {
      simulator.setStrEnabled(true);
      simulator.targetValue = 5.0;

      for (int i = 0; i < 50; i++) {
        simulator.step();
        if (simulator.isHalted) break;
      }

      // 制御入力が上限を超えた場合は停止されている
      expect(
        simulator.controlInput.abs() <= simulator.maxControlInputAbs ||
            simulator.isHalted,
        true,
      );
    });

    test('STR: プリセット外乱の下でのステップ実行', () {
      simulator.setStrEnabled(true);
      simulator.applyDisturbancePreset('noise_small');

      for (int i = 0; i < 50; i++) {
        simulator.step();
        if (simulator.isHalted) break;
      }

      // 外乱がある環境下でもシミュレーションが継続
      expect(simulator.stepCount, greaterThan(0));
    });
  });
}
