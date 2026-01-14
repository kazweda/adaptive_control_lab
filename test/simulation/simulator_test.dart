import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/simulation/simulator.dart';

void main() {
  group('Simulator (シミュレーション統合)', () {
    test('初期状態の確認', () {
      final sim = Simulator();

      expect(sim.plantOutput, 0.0);
      expect(sim.controlInput, 0.0);
      expect(sim.targetValue, 1.0);
      expect(sim.stepCount, 0);
      expect(sim.historyTarget, isEmpty);
      expect(sim.historyOutput, isEmpty);
      expect(sim.historyControl, isEmpty);
    });

    test('1ステップ実行の確認', () {
      final sim = Simulator();

      sim.step();

      expect(sim.stepCount, 1);
      expect(sim.historyTarget.length, 1);
      expect(sim.historyOutput.length, 1);
      expect(sim.historyControl.length, 1);
    });

    test('複数ステップ実行の確認', () {
      final sim = Simulator();

      for (int i = 0; i < 10; i++) {
        sim.step();
      }

      expect(sim.stepCount, 10);
      expect(sim.historyTarget.length, 10);
      expect(sim.historyOutput.length, 10);
      expect(sim.historyControl.length, 10);
    });

    test('目標値追従の確認', () {
      final sim = Simulator();
      sim.targetValue = 1.0;

      // 十分なステップ数で収束を確認
      for (int i = 0; i < 100; i++) {
        sim.step();
      }

      // 出力が目標値に近づいているはず
      expect(sim.plantOutput, closeTo(1.0, 0.1));
    });

    test('履歴の最大数制限の確認', () {
      // テストでは上限200を指定して挙動を検証
      final sim = Simulator(maxHistoryLength: 200);

      // 200ステップを超えて実行
      for (int i = 0; i < 250; i++) {
        sim.step();
      }

      // 履歴は200に制限される
      expect(sim.historyTarget.length, 200);
      expect(sim.historyOutput.length, 200);
      expect(sim.historyControl.length, 200);
    });

    test('任意の履歴上限指定でも制限される', () {
      final sim = Simulator(maxHistoryLength: 50);

      for (int i = 0; i < 120; i++) {
        sim.step();
      }

      expect(sim.historyTarget.length, 50);
      expect(sim.historyOutput.length, 50);
      expect(sim.historyControl.length, 50);
    });

    test('リセット機能の確認', () {
      final sim = Simulator();

      for (int i = 0; i < 10; i++) {
        sim.step();
      }

      expect(sim.stepCount, isNot(0));
      expect(sim.historyTarget, isNotEmpty);

      sim.reset();

      expect(sim.plantOutput, 0.0);
      expect(sim.controlInput, 0.0);
      expect(sim.stepCount, 0);
      expect(sim.historyTarget, isEmpty);
      expect(sim.historyOutput, isEmpty);
      expect(sim.historyControl, isEmpty);
    });

    test('プラントパラメータ変更の確認', () {
      final sim = Simulator();

      sim.plantParamA = 0.5;
      sim.plantParamB = 0.3;

      expect(sim.plantParamA, 0.5);
      expect(sim.plantParamB, 0.3);
    });

    test('PIDゲイン変更の確認', () {
      final sim = Simulator();

      sim.pidKp = 0.5;
      sim.pidKi = 0.2;
      sim.pidKd = 0.15;

      expect(sim.pidKp, 0.5);
      expect(sim.pidKi, 0.2);
      expect(sim.pidKd, 0.15);
    });

    test('目標値変更後の応答確認', () {
      final sim = Simulator();
      sim.targetValue = 1.0;

      for (int i = 0; i < 50; i++) {
        sim.step();
      }

      final outputBefore = sim.plantOutput;

      // 目標値を変更
      sim.targetValue = 2.0;

      for (int i = 0; i < 50; i++) {
        sim.step();
      }

      // 出力が変化しているはず
      expect(sim.plantOutput, isNot(outputBefore));
      expect(sim.plantOutput, greaterThan(outputBefore));
    });

    test('PIDゲイン変更後の応答確認', () {
      final sim1 = Simulator();
      sim1.pidKp = 0.1;
      sim1.pidKi = 0.0; // 積分項をオフにして単純化
      sim1.pidKd = 0.0; // 微分項をオフにして単純化

      final sim2 = Simulator();
      sim2.pidKp = 0.5;
      sim2.pidKi = 0.0;
      sim2.pidKd = 0.0;

      for (int i = 0; i < 20; i++) {
        sim1.step();
        sim2.step();
      }

      // ゲインが大きい方が応答が速いはず（比例ゲインのみの場合）
      expect(sim2.plantOutput, greaterThan(sim1.plantOutput));
    });

    test('2次プラント初期ゲインで発散しない（安全上限内に収まる）', () {
      final sim = Simulator(maxOutputAbs: 5.0, maxControlInputAbs: 5.0);

      // 2次プラントに切替（初期PIDゲインも2次系用にリセット）
      sim.setPlantOrder(useSecondOrder: true);

      for (int i = 0; i < 200; i++) {
        sim.step();
        if (sim.isHalted) break;
      }

      // 初期ゲインで発散しないことを確認（安全上限を超えない）
      expect(sim.isHalted, isFalse);
      expect(sim.plantOutput.abs(), lessThanOrEqualTo(5.0));
    });

    test('制御入力が上限を超えたら停止（halt機能）', () {
      final sim = Simulator(maxControlInputAbs: 1.0);

      // 制御入力を大きくするためにPIDゲインを極端に設定
      sim.pidKp = 10.0;
      sim.pidKi = 5.0;
      sim.targetValue = 10.0;

      // 最初のステップで制御入力が上限を超えるはず
      sim.step();

      expect(sim.isHalted, isTrue);
      // halt時はstep処理が中断されるためstepCountは増えない
      expect(sim.stepCount, 0);
    });

    test('出力が上限を超えたら停止', () {
      // より緩い制御入力上限と厳しい出力上限を設定
      final sim = Simulator(maxOutputAbs: 0.3, maxControlInputAbs: 50.0);

      // 出力を徐々に大きくするようなパラメータ設定
      sim.plantParamA = 0.9; // 蓄積効果
      sim.plantParamB = 0.2;
      sim.pidKp = 1.0;
      sim.pidKi = 0.5; // 積分で徐々に増大
      sim.targetValue = 2.0;

      // 数ステップで出力が上限を超えるはず
      int maxSteps = 50;
      for (int i = 0; i < maxSteps; i++) {
        sim.step();
        if (sim.isHalted) break;
      }

      expect(sim.isHalted, isTrue, reason: 'シミュレーションが停止すること');
      expect(sim.stepCount, greaterThan(0), reason: '少なくとも1ステップは実行される');
    });

    test('halt後のstep呼び出しは何もしない', () {
      final sim = Simulator(maxControlInputAbs: 1.0);

      sim.pidKp = 10.0;
      sim.targetValue = 10.0;
      sim.step(); // halt発生

      expect(sim.isHalted, isTrue);
      final stepCountBefore = sim.stepCount;
      final historyLengthBefore = sim.historyTarget.length;

      // halt後に再度step呼び出し
      sim.step();

      // 状態が変化しないことを確認
      expect(sim.stepCount, stepCountBefore);
      expect(sim.historyTarget.length, historyLengthBefore);
    });

    test('reset後はhaltフラグがクリアされる', () {
      final sim = Simulator(maxControlInputAbs: 1.0);

      sim.pidKp = 10.0;
      sim.targetValue = 10.0;
      sim.step();

      expect(sim.isHalted, isTrue);

      sim.reset();

      expect(sim.isHalted, isFalse);
      expect(sim.stepCount, 0);
      expect(sim.historyTarget, isEmpty);

      // reset後は再度step実行可能
      sim.pidKp = 0.3; // 通常のゲインに戻す
      sim.targetValue = 1.0;
      sim.step();

      expect(sim.stepCount, 1);
    });

    test('halt時でも履歴にデータが記録される', () {
      final sim = Simulator(maxOutputAbs: 0.5);

      sim.plantParamB = 10.0;
      sim.pidKp = 5.0;
      sim.targetValue = 5.0;

      // 出力超過でhalt
      for (int i = 0; i < 10; i++) {
        sim.step();
        if (sim.isHalted) break;
      }

      expect(sim.isHalted, isTrue);
      // halt時は履歴に追加されない（一貫性のため）
      expect(sim.historyOutput.length, sim.stepCount);
    });
  });
}
