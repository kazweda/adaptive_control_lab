/// PID制御器
///
/// 制御式：
/// u(k) = Kp * e(k) + Ki * Σe(k) + Kd * Δe(k)
///
/// - Kp: 比例ゲイン（素早く反応する程度）
/// - Ki: 積分ゲイン（ズレを直す強さ）
/// - Kd: 微分ゲイン（揺れを抑える程度）
/// - e(k): 誤差（目標値 - 現在値）
class PIDController {
  // PIDゲイン
  double kp; // 比例ゲイン
  double ki; // 積分ゲイン
  double kd; // 微分ゲイン

  // 内部状態
  double _errorSum = 0.0; // 誤差の積分値 Σe(k)
  double _previousError = 0.0; // 前のステップの誤差 e(k-1)

  /// コンストラクタ
  PIDController({this.kp = 0.3, this.ki = 0.1, this.kd = 0.1});

  /// 制御入力を計算
  ///
  /// [error] 現在の誤差 e(k) = 目標値 - 現在値
  /// 戻り値：制御入力 u(k)
  double compute(double error) {
    // 比例項：Kp * e(k)
    final pTerm = kp * error;

    // 積分項：Ki * Σe(k)
    _errorSum += error;
    final iTerm = ki * _errorSum;

    // 微分項：Kd * Δe(k)
    final dTerm = kd * (error - _previousError);

    // 制御入力を計算
    final output = pTerm + iTerm + dTerm;

    // 次のステップのために現在の誤差を保存
    _previousError = error;

    return output;
  }

  /// 制御器の状態をリセット
  void reset() {
    _errorSum = 0.0;
    _previousError = 0.0;
  }

  /// デバッグ用の文字列表現
  @override
  String toString() {
    return 'PID(Kp: $kp, Ki: $ki, Kd: $kd)';
  }
}
