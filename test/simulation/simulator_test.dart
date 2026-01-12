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
  });
}
