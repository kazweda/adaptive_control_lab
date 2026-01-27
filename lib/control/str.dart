import 'rls.dart';
import 'dart:math';

/// Self-Tuning Regulator (STR)
/// オンライン同定（RLS）と極配置制御則を組み合わせた適応制御器
class STR {
  final int parameterCount; // プラント次数: 1次=2, 2次=4
  final RLS rls;
  double targetPole1; // 所望の極1（1次・2次共通）
  double targetPole2; // 所望の極2（2次のみ）

  /// 制御入力の安全上限（オーバーフロー対策）
  /// 初期推定値が不確定な場合、大きな制御入力が発生する可能性があるため制限
  double controlInputLimit = 10.0;

  /// 段階的極配置の有効化フラグ
  /// 有効時: 初期段階は緩い極で保守的に制御し、推定が収束したら所望の極に移行
  bool _enableAdaptivePolePlacement = false;

  /// 段階的極配置の初期極値（デフォルト: 0.75）
  double _initialPoleValue = 0.75;

  /// 段階的極配置の収束ステップ数
  int _polePlacementConvergenceSteps = 100;

  /// 段階的制御入力制限の有効化フラグ
  /// 有効時: 初期段階は±1.0に制限し、推定収束後に±10.0に緩和
  bool _enableAdaptiveControlLimit = false;

  /// 制御入力の初期制限値（推定精度が低い初期段階）
  double _initialControlInputLimit = 1.0;

  /// 制御入力制限の収束ステップ数
  int _controlLimitConvergenceSteps = 100;

  /// 初期ステップでのソフトスタートを有効化
  bool _enableSoftStart = false;

  /// ソフトスタート期間（ステップ数）
  int _softStartSteps = 30;

  /// ソフトスタート時の入力スケール初期値
  double _softStartInitialScale = 0.2;

  /// 制御ステップ数カウンター（段階的制御用）
  int _stepCount = 0;

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
  /// 返値は安全性のため [-controlInputLimit, controlInputLimit] にクリップされる
  double computeControl(double y, double r) {
    _stepCount++;

    // 段階的極配置: 推定が収束するまでは緩い極を使用
    final currentPole1 = _getAdaptivePole1();
    final currentPole2 = _getAdaptivePole2();

    double u;

    if (parameterCount == 2) {
      // 1次プラント: y(k) = a*y(k-1) + b*u(k-1)
      final a = rls.estimatedA;
      final b = rls.estimatedB;
      u = _computeControl1st(a, b, currentPole1, y, r);
    } else if (parameterCount == 4) {
      // 2次プラント: y(k) = a1*y(k-1) + a2*y(k-2) + b1*u(k-1) + b2*u(k-2)
      final a1 = rls.estimatedA1;
      final a2 = rls.estimatedA2;
      final b1 = rls.estimatedB1;
      final b2 = rls.estimatedB2;
      u = _computeControl2nd(a1, a2, b1, b2, currentPole1, currentPole2, y, r);
    } else {
      throw ArgumentError('Unsupported parameter count: $parameterCount');
    }

    // 段階的制御入力制限
    final limit = _getAdaptiveControlLimit();

    // 初期のソフトスタート（2次系初期推定の不確実性を緩和）
    final softScale = _getSoftStartScale();
    final scaled = u * softScale;

    // 制御入力の安全制限（オーバーフロー対策）
    // 初期的に推定パラメータが不確定なため、大きな制御入力が発生する可能性がある
    // 最初のステップ付近では慎重に制御する
    final clamped = scaled.clamp(-limit, limit).toDouble();

    // 過去値を記録（実際に適用する値で更新する）
    _updateHistory(y, clamped);

    return clamped;
  }

  /// 段階的に適用する極1を取得
  /// _enableAdaptivePolePlacement有効時: 初期段階は緩い極、収束後は所望の極
  double _getAdaptivePole1() {
    if (!_enableAdaptivePolePlacement ||
        _stepCount >= _polePlacementConvergenceSteps) {
      return targetPole1;
    }

    // 線形補間: 初期段階から所望の極へ移行
    final progress = _stepCount / _polePlacementConvergenceSteps;
    return _initialPoleValue + (targetPole1 - _initialPoleValue) * progress;
  }

  /// 段階的に適用する極2を取得
  double _getAdaptivePole2() {
    if (!_enableAdaptivePolePlacement ||
        _stepCount >= _polePlacementConvergenceSteps) {
      return targetPole2;
    }

    // 線形補間
    final progress = _stepCount / _polePlacementConvergenceSteps;
    return _initialPoleValue + (targetPole2 - _initialPoleValue) * progress;
  }

  /// 段階的に適用する制御入力制限を取得
  /// _enableAdaptiveControlLimit有効時: 初期段階は±1.0、収束後は±10.0
  double _getAdaptiveControlLimit() {
    if (!_enableAdaptiveControlLimit ||
        _stepCount >= _controlLimitConvergenceSteps) {
      return controlInputLimit;
    }

    // 線形補間: 初期制限から最大制限へ移行
    final progress = _stepCount / _controlLimitConvergenceSteps;
    return _initialControlInputLimit +
        (controlInputLimit - _initialControlInputLimit) * progress;
  }

  /// ソフトスタート用スケーリング係数を取得
  double _getSoftStartScale() {
    if (!_enableSoftStart || _stepCount >= _softStartSteps) {
      return 1.0;
    }
    final progress = _stepCount / _softStartSteps;
    return _softStartInitialScale + (1.0 - _softStartInitialScale) * progress;
  }

  /// 1次プラント用制御則（極配置 + リファレンスゲイン）
  /// u(k) = ((1 - p_d) * r(k) - (a - p_d) * y(k)) / b
  /// ※ (1 - p_d) がリファレンスゲイン（DCゲインを1に補正）
  double _computeControl1st(double a, double b, double p, double y, double r) {
    // b=0の場合は安全のため0を返す
    if (b.abs() < 1e-8) {
      return 0.0;
    }

    final numerator = (1 - p) * r - (a - p) * y;
    return numerator / b;
  }

  /// 2次プラント用制御則（極配置 + リファレンスゲイン）
  /// u(k) = (1/b1) * [ (1 - p1 - p2 - p1*p2) * r(k)
  ///                 - (a1 - (p1 + p2)) * y(k)
  ///                 - (a2 - p1*p2) * y(k-1)
  ///                 - b2 * u(k-1) ]
  /// ※ (1 - p1 - p2 - p1*p2) がリファレンスゲイン（DCゲインを1に補正）
  double _computeControl2nd(
    double a1,
    double a2,
    double b1,
    double b2,
    double p1,
    double p2,
    double y,
    double r,
  ) {
    // b1=0の場合は安全のため0を返す
    if (b1.abs() < 1e-8) {
      return 0.0;
    }

    final p1p2Sum = p1 + p2;
    final p1p2Prod = p1 * p2;

    final term1 = (1 - p1p2Sum - p1p2Prod) * r;
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
    _stepCount = 0;
  }

  /// 段階的極配置を有効化
  /// [initialPole] 初期段階での緩い極（デフォルト: 0.75）
  /// [convergenceSteps] 推定が収束したと判定するステップ数
  void enableAdaptivePolePlacement({
    double initialPole = 0.75,
    int convergenceSteps = 100,
  }) {
    _enableAdaptivePolePlacement = true;
    _initialPoleValue = initialPole;
    _polePlacementConvergenceSteps = convergenceSteps;
  }

  /// 段階的制御入力制限を有効化
  /// [initialLimit] 初期段階での制御入力制限（デフォルト: ±1.0）
  /// [convergenceSteps] 推定が収束したと判定するステップ数
  void enableAdaptiveControlLimit({
    double initialLimit = 1.0,
    int convergenceSteps = 100,
  }) {
    _enableAdaptiveControlLimit = true;
    _initialControlInputLimit = initialLimit;
    _controlLimitConvergenceSteps = convergenceSteps;
  }

  /// ソフトスタートを有効化（初期ステップで入力をスケールダウン）
  void enableSoftStart({double initialScale = 0.2, int steps = 30}) {
    _enableSoftStart = true;
    _softStartInitialScale = initialScale;
    _softStartSteps = steps;
  }

  /// 段階的制御を無効化
  void disableAdaptiveControl() {
    _enableAdaptivePolePlacement = false;
    _enableAdaptiveControlLimit = false;
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
