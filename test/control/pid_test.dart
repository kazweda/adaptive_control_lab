import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/pid.dart';

void main() {
  group('PIDController (PID制御器)', () {
    test('初期状態の確認', () {
      final pid = PIDController(kp: 0.3, ki: 0.1, kd: 0.1);

      expect(pid.kp, 0.3);
      expect(pid.ki, 0.1);
      expect(pid.kd, 0.1);
    });

    test('比例項のみ（Kp）の動作確認', () {
      final pid = PIDController(kp: 1.0, ki: 0.0, kd: 0.0);

      final output = pid.compute(0.5);

      // u = 1.0 * 0.5 = 0.5
      expect(output, 0.5);
    });

    test('積分項のみ（Ki）の動作確認', () {
      final pid = PIDController(kp: 0.0, ki: 1.0, kd: 0.0);

      pid.compute(0.5); // Σe = 0.5
      final output = pid.compute(0.5); // Σe = 1.0

      // u = 1.0 * 1.0 = 1.0
      expect(output, 1.0);
    });

    test('微分項のみ（Kd）の動作確認', () {
      final pid = PIDController(kp: 0.0, ki: 0.0, kd: 1.0);

      pid.compute(0.5); // Δe = 0.5 - 0.0 = 0.5
      final output = pid.compute(1.0); // Δe = 1.0 - 0.5 = 0.5

      // u = 1.0 * 0.5 = 0.5
      expect(output, 0.5);
    });

    test('PID全項の動作確認', () {
      final pid = PIDController(kp: 0.5, ki: 0.2, kd: 0.1);

      // 1ステップ目: e = 1.0
      final output1 = pid.compute(1.0);
      // P: 0.5*1.0=0.5, I: 0.2*1.0=0.2, D: 0.1*(1.0-0.0)=0.1
      // u = 0.5 + 0.2 + 0.1 = 0.8
      expect(output1, closeTo(0.8, 0.001));

      // 2ステップ目: e = 0.5
      final output2 = pid.compute(0.5);
      // P: 0.5*0.5=0.25, I: 0.2*1.5=0.3, D: 0.1*(0.5-1.0)=-0.05
      // u = 0.25 + 0.3 - 0.05 = 0.5
      expect(output2, closeTo(0.5, 0.001));
    });

    test('リセット機能の確認', () {
      final pid = PIDController(kp: 1.0, ki: 1.0, kd: 1.0);

      pid.compute(1.0);
      pid.compute(1.0);

      // リセット前は内部状態がある
      final outputBefore = pid.compute(0.0);
      expect(outputBefore, isNot(0.0));

      pid.reset();

      // リセット後は内部状態がクリア
      final outputAfter = pid.compute(0.0);
      expect(outputAfter, 0.0);
    });

    test('ゲイン変更の反映確認', () {
      final pid = PIDController(kp: 1.0, ki: 0.0, kd: 0.0);

      final output1 = pid.compute(1.0);
      expect(output1, 1.0);

      // ゲイン変更
      pid.kp = 2.0;

      pid.reset();
      final output2 = pid.compute(1.0);
      expect(output2, 2.0);
    });

    test('誤差ゼロ時の動作確認', () {
      final pid = PIDController(kp: 1.0, ki: 1.0, kd: 1.0);

      final output = pid.compute(0.0);

      expect(output, 0.0);
    });

    test('負の誤差への対応確認', () {
      final pid = PIDController(kp: 1.0, ki: 0.0, kd: 0.0);

      final output = pid.compute(-0.5);

      expect(output, -0.5);
    });
  });
}
