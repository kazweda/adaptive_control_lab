import 'rls.dart';
import 'dart:math';

/// Self-Tuning Regulator (STR)
/// オンライン同定（RLS）と極配置制御則を組み合わせた適応制御器
class STR {
  final int parameterCount; // プラント次数: 1次=2, 2次=4
  final RLS rls;
  double targetPole1; // 所望の極1（1次・2次共通）
  double targetPole2; // 所望の極2（2次のみ）

  final List<double> _previousOutputs = []; // y(k-1), y(k-2)
  final List<double> _previousInputs = []; // u(k-1), u(k-2)

  /// コンストラクタ
  STR({
    required this.parameterCount,
    required this.rls,
    this.targetPole1 = 0.5,
    this.targetPole2 = 0.3,
  }) {
    _validateTargetPoles();
  }

  /// 所望の極の妥当性チェック（単位円内）
  void _validateTargetPoles() {
    if (targetPole1.abs() >= 1.0 || targetPole2.abs() >= 1.0) {
      throw ArgumentError('Target poles must be inside unit circle: |p| < 1.0');
    }
  }

  /// 制御入力を計算
  /// y: 現在の出力, r: 目標値（参照信号）
  double computeControl(double y, double r) {
    double u;

    if (parameterCount == 2) {
      // 1次プラント: y(k) = a*y(k-1) + b*u(k-1)
      final a = rls.estimatedA;
      final b = rls.estimatedB;
      u = _computeControl1st(a, b, y, r);
    } else if (parameterCount == 4) {
      // 2次プラント: y(k) = a1*y(k-1) + a2*y(k-2) + b1*u(k-1) + b2*u(k-2)
      final a1 = rls.estimatedA1;
      final a2 = rls.estimatedA2;
      final b1 = rls.estimatedB1;
      final b2 = rls.estimatedB2;
      u = _computeControl2nd(a1, a2, b1, b2, y, r);
    } else {
      throw ArgumentError('Unsupported parameter count: $parameterCount');
    }

    // 過去値を記録
    _updateHistory(y, u);

    return u;
  }

  /// 1次プラント用制御則（極配置）
  /// u(k) = (r(k) - (a - p_d)*y(k)) / b
  double _computeControl1st(double a, double b, double y, double r) {
    // b=0の場合は安全のため0を返す
    if (b.abs() < 1e-8) {
      return 0.0;
    }

    final numerator = r - (a - targetPole1) * y;
    return numerator / b;
  }

  /// 2次プラント用制御則（極配置）
  /// u(k) = (1/b1) * [r(k) - (a1 - p1 - p2)*y(k) - (a2 - p1*p2)*y(k-1) - b2*u(k-1)]
  double _computeControl2nd(
    double a1,
    double a2,
    double b1,
    double b2,
    double y,
    double r,
  ) {
    // b1=0の場合は安全のため0を返す
    if (b1.abs() < 1e-8) {
      return 0.0;
    }

    final p1p2Sum = targetPole1 + targetPole2;
    final p1p2Prod = targetPole1 * targetPole2;

    final term1 = r;
    final term2 = (a1 - p1p2Sum) * y;
    final term3 =
        (a2 - p1p2Prod) *
        (_previousOutputs.isNotEmpty ? _previousOutputs[0] : 0);
    final term4 = b2 * (_previousInputs.isNotEmpty ? _previousInputs[0] : 0);

    return (term1 - term2 - term3 - term4) / b1;
  }

  /// 過去値を更新（キューイング）
  void _updateHistory(double y, double u) {
    _previousOutputs.insert(0, y);
    if (_previousOutputs.length > 2) {
      _previousOutputs.removeLast();
    }

    _previousInputs.insert(0, u);
    if (_previousInputs.length > 2) {
      _previousInputs.removeLast();
    }
  }

  /// リセット
  void reset() {
    rls.reset();
    _previousOutputs.clear();
    _previousInputs.clear();
  }

  /// ゲッター: 1次系用
  double get estimatedA => rls.estimatedA;
  double get estimatedB => rls.estimatedB;

  /// ゲッター: 2次系用
  double get estimatedA1 => rls.estimatedA1;
  double get estimatedA2 => rls.estimatedA2;
  double get estimatedB1 => rls.estimatedB1;
  double get estimatedB2 => rls.estimatedB2;

  /// 所望の極を設定
  void setTargetPoles(double p1, double p2) {
    targetPole1 = p1;
    targetPole2 = p2;
    _validateTargetPoles();
  }

  /// 所望の極をシステム応答に基づいて自動調整（オプション）
  /// 例：Butterworth配置（平坦な周波数応答）
  void setTargetPolesButterworth(double bandwidth) {
    // 2次Butterworth極（正規化周波数w_n=bandwidth）
    // p1, p2 = -ζ*w_n ± j*w_n*sqrt(1-ζ^2)
    // 離散化後の極位置（簡易版）
    final zeta = 1.0 / sqrt(2); // ζ=0.707（最大平坦）
    final wn = bandwidth;

    // 連続時間極から離散時間極への変換（s = (z-1)/Ts, Ts=1）
    // ここではシンプルに：
    final realPart = exp(-zeta * wn);
    // 複素極を実数近似（虚部は参考値のため使用しない）

    // 複素極を実数近似（とりあえず実部のみ）
    targetPole1 = realPart;
    targetPole2 = realPart * 0.8; // 2番目の極は少し小さく

    _validateTargetPoles();
  }

  @override
  String toString() {
    return 'STR(paramCount=$parameterCount, p1=$targetPole1, p2=$targetPole2)';
  }
}
