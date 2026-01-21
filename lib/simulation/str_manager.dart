import '../control/rls.dart';
import '../control/str.dart';

/// STR/RLS のライフサイクルと設定を集約するマネージャー
///
/// Simulator から STR 関連の初期化・切替・パラメータ設定の責務を分離する。
class StrManager {
  StrManager({
    required bool useSecondOrderPlant,
    this.rlsLambda = 0.98,
    this.strTargetPole1 = 0.5,
    this.strTargetPole2 = 0.3,
    this.initialCovarianceScale = 100.0,
  }) : _useSecondOrderPlant = useSecondOrderPlant;

  bool _useSecondOrderPlant;

  // RLS 設定
  bool rlsEnabled = false;
  double rlsLambda;
  RLS? rls;

  // STR 設定
  bool strEnabled = false;
  double strTargetPole1;
  double strTargetPole2;
  STR? str;

  // 初期共分散スケール（Issue #37 対策値）
  final double initialCovarianceScale;

  bool get useSecondOrderPlant => _useSecondOrderPlant;

  void updatePlantOrder(bool useSecondOrder) {
    _useSecondOrderPlant = useSecondOrder;
    _initializeRls();
    _initializeStr();
  }

  void setRlsEnabled(bool enabled) {
    rlsEnabled = enabled;
    _initializeRls();
  }

  void setStrEnabled(bool enabled) {
    strEnabled = enabled;
    _initializeStr();
  }

  void setRlsLambda(double lambda) {
    rlsLambda = lambda;
    if (rlsEnabled) {
      _initializeRls();
    }
    if (strEnabled) {
      _initializeStr();
    }
  }

  void setStrTargetPoles(double p1, double p2) {
    strTargetPole1 = p1;
    strTargetPole2 = p2;
    str?.setTargetPoles(p1, p2);
  }

  void setStrTargetPolesButterworth(double bandwidth) {
    // STR が有効な場合は、そのインスタンスに設定してから値を保存する
    if (str != null) {
      str!.setTargetPolesButterworth(bandwidth);
      strTargetPole1 = str!.targetPole1;
      strTargetPole2 = str!.targetPole2;
      return;
    }

    // STR が無効な場合でも、Butterworth 極を事前計算して保持しておく。
    // これにより、後で setStrEnabled(true) が呼ばれた際に、
    // Butterworth 由来の極で STR が初期化される。
    final paramCount = _useSecondOrderPlant ? 4 : 2;
    final tempRls = RLS(
      parameterCount: paramCount,
      lambda: rlsLambda,
      initialCovarianceScale: initialCovarianceScale,
    );
    final tempStr = STR(
      parameterCount: paramCount,
      rls: tempRls,
      targetPole1: strTargetPole1,
      targetPole2: strTargetPole2,
    );
    tempStr.setTargetPolesButterworth(bandwidth);
    strTargetPole1 = tempStr.targetPole1;
    strTargetPole2 = tempStr.targetPole2;
  }

  void resetControllers() {
    rls?.reset();
    str?.reset();
  }

  void _initializeRls() {
    if (!rlsEnabled) {
      rls = null;
      return;
    }
    final paramCount = _useSecondOrderPlant ? 4 : 2;
    rls = RLS(
      parameterCount: paramCount,
      lambda: rlsLambda,
      initialCovarianceScale: initialCovarianceScale,
    );
  }

  void _initializeStr() {
    if (!strEnabled) {
      str = null;
      return;
    }
    final paramCount = _useSecondOrderPlant ? 4 : 2;
    final strRls = RLS(
      parameterCount: paramCount,
      lambda: rlsLambda,
      initialCovarianceScale: initialCovarianceScale,
    );
    str = STR(
      parameterCount: paramCount,
      rls: strRls,
      targetPole1: strTargetPole1,
      targetPole2: strTargetPole2,
    );
  }
}
