import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/second_order_plant.dart';

void main() {
  group('SecondOrderPlant (2次系プラントモデル)', () {
    test('初期状態の確認', () {
      final plant = SecondOrderPlant();
      expect(plant.output, 0.0);
    });

    test('1〜3ステップ更新の動作確認', () {
      final plant = SecondOrderPlant(a1: 1.6, a2: -0.64, b1: 0.5, b2: 0.2);

      // u(0) = 1.0 を入力
      final y1 = plant.step(1.0);
      // y(1) = a1*y(0) + a2*y(-1) + b1*u(0) + b2*u(-1)
      // 初期は y(0)=0, y(-1)=0, u(-1)=0 なので 0.0
      expect(y1, 0.0);

      // u(1) = 1.0 を入力
      final y2 = plant.step(1.0);
      // y(2) = a1*0.0 + a2*0.0 + b1*1.0 + b2*0.0 = b1 = 0.5
      expect(y2, closeTo(0.5, 1e-6));

      // u(2) = 1.0 を入力
      final y3 = plant.step(1.0);
      // y(3) = a1*y(2) + a2*y(1) + b1*u(1) + b2*u(0)
      //      = 1.6*0.5 + (-0.64)*0.0 + 0.5*1.0 + 0.2*1.0 = 0.8 + 0.5 + 0.2 = 1.5
      expect(y3, closeTo(1.5, 1e-6));
    });

    test('リセット機能の確認', () {
      final plant = SecondOrderPlant();
      plant.step(1.0);
      plant.step(1.0);
      expect(plant.output, isNot(0.0));

      plant.reset();
      expect(plant.output, 0.0);
    });

    test('安定性の確認（極が単位円内にある場合）', () {
      final plant = SecondOrderPlant(
        a1: 1.6,
        a2: -0.64, // 0.8 の重根（安定）
        b1: 0.5,
        b2: 0.2,
      );

      // 一定入力を与えた場合、出力は定常値に収束するはず
      for (int i = 0; i < 200; i++) {
        plant.step(1.0);
      }

      // 理論値: y = (b1 + b2) / (1 - a1 - a2)
      // a1=1.6, a2=-0.64 → 1 - a1 - a2 = 0.04
      // b1+b2 = 0.7 → y = 0.7 / 0.04 = 17.5
      expect(plant.output, closeTo(17.5, 0.05));
    });
  });
}
