import '../control/rls.dart';
import '../control/str.dart';

/// STR所望極のプリセット定義
class STRPreset {
  final String name;
  final String displayName;
  final String description;
  final double pole1;
  final double pole2;

  const STRPreset({
    required this.name,
    required this.displayName,
    required this.description,
    required this.pole1,
    required this.pole2,
  });
}

/// STR/RLS のライフサイクルと設定を集約するマネージャー
///
/// Simulator から STR 関連の初期化・切替・パラメータ設定の責務を分離する。
class StrManager {
  StrManager({
    required bool useSecondOrderPlant,
    this.rlsLambda = 0.995,
    this.strTargetPole1 = 0.5,
    this.strTargetPole2 = 0.3,
    this.initialCovarianceScale = 1.0,
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

  /// 現在適用中の極プリセット名（手動で極を変更すると'カスタム'になる）
  String currentPresetName = '標準';

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
    currentPresetName = 'カスタム';
  }

  /// 極プリセット一覧を取得
  static List<STRPreset> getAvailablePresets() {
    return const [
      STRPreset(
        name: 'stable',
        displayName: '安定重視',
        description: '収束はゆっくりだが安定性重視',
        pole1: 0.7,
        pole2: 0.5,
      ),
      STRPreset(
        name: 'standard',
        displayName: '標準',
        description: 'バランス重視のデフォルト',
        pole1: 0.5,
        pole2: 0.3,
      ),
      STRPreset(
        name: 'fast',
        displayName: '速応答',
        description: '速く収束、外乱に敏感になる場合あり',
        pole1: 0.25,
        pole2: 0.15,
      ),
    ];
  }

  /// 極プリセットを適用
  void applyPreset(String presetName) {
    final preset = getAvailablePresets().firstWhere(
      (p) => p.name == presetName,
      orElse: () => getAvailablePresets()[1],
    );
    strTargetPole1 = preset.pole1;
    strTargetPole2 = preset.pole2;
    str?.setTargetPoles(preset.pole1, preset.pole2);
    currentPresetName = preset.displayName;
  }

  void setStrTargetPolesButterworth(double bandwidth) {
    // STR が有効な場合は、そのインスタンスに設定してから値を保存する
    if (str != null) {
      str!.setTargetPolesButterworth(bandwidth);
      strTargetPole1 = str!.targetPole1;
      strTargetPole2 = str!.targetPole2;
      currentPresetName = 'カスタム';
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
    currentPresetName = 'カスタム';
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
      // UIデフォルトのプラント(1次: a=0.8, b=0.5)に合わせた初期推定値
      initialTheta: paramCount == 2 ? [0.8, 0.5] : null,
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
      // UIデフォルトのプラント(1次: a=0.8, b=0.5)に合わせた初期推定値
      initialTheta: paramCount == 2 ? [0.8, 0.5] : null,
    );
    str = STR(
      parameterCount: paramCount,
      rls: strRls,
      targetPole1: strTargetPole1,
      targetPole2: strTargetPole2,
    );
    // 2次系は初期推定が不確かなのでソフトスタートを有効化
    if (paramCount == 4) {
      str!.enableSoftStart(initialScale: 0.2, steps: 30);
    }
  }
}
