import '../control/pid.dart';

/// PID制御ロジックを `Simulator` から切り離して管理するクラス
///
/// Simulator からPID制御器の生成・保持・リセットとPIDゲインの参照/更新の責務を委譲されます。
/// これにより、Simulator は制御対象プラントや外乱の管理に集中でき、
/// PID制御の詳細な実装はこのクラスに集約されます。
///
/// ## 主な責務
/// - 現在使用中の [PIDController] インスタンスを保持し、そのライフサイクルを管理
/// - 誤差 e(k) から制御入力 u(k) を計算する [computeControl] を提供
/// - kp, ki, kd のゲインをゲッター/セッターとして公開
/// - シミュレーションのリスタート時に [reset] でPID内部状態をクリア
///
/// ## 静的ファクトリメソッドの使い分け
/// - [createFirstOrderDefault]: 1次プラントモデル向けの標準的なPIDゲイン
/// - [createSecondOrderDefault]: 2次プラント向けに発散を避けるため抑えめのゲイン
///
/// これらは初期値（プリセット）であり、実際のチューニングは
/// シミュレーション結果を見ながらゲインを動的に変更して行います。
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
}
