import '../control/pid.dart';

/// PID制御の責務を分離（Simulator から委譲）
class PIDManager {
  late PIDController pidController;

  /// コンストラクタ
  PIDManager(PIDController initialController) {
    pidController = initialController;
  }

  /// 誤差から制御入力を計算
  double computeControl(double error) {
    return pidController.compute(error);
  }

  // === PIDゲイン アクセサ ===

  double get kp => pidController.kp;
  set kp(double value) => pidController.kp = value;

  double get ki => pidController.ki;
  set ki(double value) => pidController.ki = value;

  double get kd => pidController.kd;
  set kd(double value) => pidController.kd = value;

  /// コントローラーをリセット
  void reset() => pidController.reset();

  /// 1次プラント向けの標準PIDゲインを作成
  static PIDController createFirstOrderDefault() {
    return PIDController(kp: 0.3, ki: 0.1, kd: 0.1);
  }

  /// 2次プラント向けの標準PIDゲインを作成
  static PIDController createSecondOrderDefault() {
    // 2次プラントはより抑えめのゲインで初期化（発散防止）
    return PIDController(kp: 0.12, ki: 0.02, kd: 0.04);
  }

  /// プラント次数に応じてコントローラーを初期化
  static PIDController createForPlantOrder({required bool useSecondOrder}) {
    return useSecondOrder
        ? createSecondOrderDefault()
        : createFirstOrderDefault();
  }
}
