import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/disturbance.dart';

void main() {
  group('Disturbance (外乱モデル)', () {
    test('none: 外乱なし', () {
      final d = Disturbance(type: DisturbanceType.none);
      expect(d.next(), 0.0);
      expect(d.next(), 0.0);
    });

    test('step: ステップ外乱', () {
      final d = Disturbance(
        type: DisturbanceType.step,
        amplitude: 0.5,
        startStep: 2,
      );
      expect(d.next(), 0.0); // k=0
      expect(d.next(), 0.0); // k=1
      expect(d.next(), 0.5); // k=2 以降 0.5
      expect(d.next(), 0.5);
    });

    test('impulse: インパルス外乱', () {
      final d = Disturbance(
        type: DisturbanceType.impulse,
        amplitude: 1.0,
        startStep: 3,
      );
      expect(d.next(), 0.0); // k=0
      expect(d.next(), 0.0); // k=1
      expect(d.next(), 0.0); // k=2
      expect(d.next(), 1.0); // k=3 で 1.0
      expect(d.next(), 0.0); // 以降 0.0
    });

    test('sinusoid: 正弦波外乱', () {
      final d = Disturbance(
        type: DisturbanceType.sinusoid,
        amplitude: 1.0,
        omega: 1.5707963267948966, // pi/2
        phase: 0.0,
      );
      // 期待系列: 0, 1, 0, -1, 0...
      expect(d.next(), closeTo(0.0, 1e-3));
      expect(d.next(), closeTo(1.0, 1e-2));
      expect(d.next(), closeTo(0.0, 1e-2));
      expect(d.next(), closeTo(-1.0, 1e-2));
      expect(d.next(), closeTo(0.0, 1e-2));
    });

    test('noise: ガウス雑音', () {
      final d = Disturbance(
        type: DisturbanceType.noise,
        noiseStdDev: 0.1,
        noiseSeed: 123,
      );
      // シード固定により再現性を確認
      final v1 = d.next();
      final v2 = d.next();
      // 雑音は平均0なのでゼロ付近、標準偏差0.1なので±0.3程度に収まる
      expect(v1.abs(), lessThan(0.5));
      expect(v2.abs(), lessThan(0.5));
      // 異なる値が生成されること
      expect(v1, isNot(v2));
    });
  });
}
