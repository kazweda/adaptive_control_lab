import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/simulation/pid_manager.dart';
import 'package:adaptive_control_lab/control/pid.dart';

void main() {
  group('PIDManager', () {
    late PIDManager manager;

    setUp(() {
      manager = PIDManager(PIDController(kp: 0.5, ki: 0.1, kd: 0.05));
    });

    test('初期状態でゲインが正しく設定される', () {
      expect(manager.kp, 0.5);
      expect(manager.ki, 0.1);
      expect(manager.kd, 0.05);
    });

    test('computeControl で制御入力を計算', () {
      final control1 = manager.computeControl(1.0);
      expect(control1, isNotNull);

      // 2回目の呼び出しで積分項が蓄積される
      final control2 = manager.computeControl(1.0);
      expect(control2, greaterThan(control1));
    });

    test('ゲインの変更が反映される', () {
      manager.kp = 1.0;
      manager.ki = 0.5;
      manager.kd = 0.2;

      expect(manager.kp, 1.0);
      expect(manager.ki, 0.5);
      expect(manager.kd, 0.2);
    });

    test('reset でPID内部状態がクリアされる', () {
      // 誤差を与えて積分項を蓄積
      manager.computeControl(1.0);
      manager.computeControl(1.0);
      final beforeReset = manager.computeControl(0.0);

      // リセット後、同じ誤差で計算
      manager.reset();
      final afterReset = manager.computeControl(0.0);

      // 積分項がクリアされるため、リセット後の出力は異なる
      expect(afterReset, isNot(equals(beforeReset)));
    });

    test('createFirstOrderDefault は1次プラント向けゲインを生成', () {
      final pid = PIDManager.createFirstOrderDefault();
      expect(pid.kp, 0.3);
      expect(pid.ki, 0.1);
      expect(pid.kd, 0.1);
    });

    test('createSecondOrderDefault は2次プラント向けゲインを生成', () {
      final pid = PIDManager.createSecondOrderDefault();
      expect(pid.kp, 0.12);
      expect(pid.ki, 0.02);
      expect(pid.kd, 0.04);
    });

    test('createSecondOrderDefault は createFirstOrderDefault より控えめ', () {
      final first = PIDManager.createFirstOrderDefault();
      final second = PIDManager.createSecondOrderDefault();

      expect(second.kp, lessThan(first.kp));
      expect(second.ki, lessThan(first.ki));
      expect(second.kd, lessThan(first.kd));
    });

    test('異なる初期ゲインでPIDManagerを生成できる', () {
      final manager1 = PIDManager(PIDManager.createFirstOrderDefault());
      final manager2 = PIDManager(PIDManager.createSecondOrderDefault());

      expect(manager1.kp, isNot(equals(manager2.kp)));
      expect(manager1.ki, isNot(equals(manager2.ki)));
      expect(manager1.kd, isNot(equals(manager2.kd)));
    });

    test('ゼロ誤差での制御入力計算', () {
      final control = manager.computeControl(0.0);
      expect(control, isA<double>());
    });

    test('負の誤差での制御入力計算', () {
      final control = manager.computeControl(-1.0);
      expect(control, isA<double>());
      expect(control, lessThan(0.0)); // 負の誤差には負の制御入力
    });

    test('連続したステップでの動作確認', () {
      final errors = [1.0, 0.8, 0.5, 0.2, 0.0];
      final controls = <double>[];

      for (final error in errors) {
        controls.add(manager.computeControl(error));
      }

      // 誤差が減少していくので、制御入力も減少傾向
      expect(controls.length, 5);
      expect(controls.first, greaterThan(controls.last));
    });
  });
}
