import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/plant.dart';

void main() {
  group('Plant (1次系プラントモデル)', () {
    test('初期状態の確認', () {
      final plant = Plant(a: 0.8, b: 0.5);

      expect(plant.a, 0.8);
      expect(plant.b, 0.5);
      expect(plant.output, 0.0);
    });

    test('1ステップ更新の動作確認', () {
      final plant = Plant(a: 0.8, b: 0.5);

      // u(0) = 1.0 を入力
      final output1 = plant.step(1.0);

      // y(1) = 0.8 * 0.0 + 0.5 * 0.0 = 0.0
      expect(output1, 0.0);

      // u(1) = 1.0 を入力
      final output2 = plant.step(1.0);

      // y(2) = 0.8 * 0.0 + 0.5 * 1.0 = 0.5
      expect(output2, 0.5);
    });

    test('複数ステップの動作確認', () {
      final plant = Plant(a: 0.8, b: 0.5);

      plant.step(1.0); // y(1) = 0.0
      plant.step(1.0); // y(2) = 0.5
      plant.step(1.0); // y(3) = 0.8 * 0.5 + 0.5 * 1.0 = 0.9

      expect(plant.output, closeTo(0.9, 0.001));
    });

    test('リセット機能の確認', () {
      final plant = Plant(a: 0.8, b: 0.5);

      plant.step(1.0);
      plant.step(1.0);
      expect(plant.output, isNot(0.0));

      plant.reset();
      expect(plant.output, 0.0);
    });

    test('パラメータ変更の反映確認', () {
      final plant = Plant(a: 0.5, b: 0.3);

      plant.step(1.0); // y(1) = 0.0
      plant.step(1.0); // y(2) = 0.5 * 0.0 + 0.3 * 1.0 = 0.3

      expect(plant.output, closeTo(0.3, 0.001));

      // パラメータ変更
      plant.a = 0.9;
      plant.b = 0.6;

      plant.step(1.0); // y(3) = 0.9 * 0.3 + 0.6 * 1.0 = 0.87
      expect(plant.output, closeTo(0.87, 0.001));
    });

    test('安定性の確認（|a| < 1）', () {
      final plant = Plant(a: 0.9, b: 0.1);

      // 一定入力を与えた場合、出力は収束するはず
      for (int i = 0; i < 100; i++) {
        plant.step(1.0);
      }

      // 理論値: y = b / (1 - a) = 0.1 / 0.1 = 1.0 に収束
      expect(plant.output, closeTo(1.0, 0.01));
    });
  });
}
