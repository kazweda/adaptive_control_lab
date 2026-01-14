import '../control/plant.dart';
import '../control/second_order_plant.dart';
import '../control/plant_model.dart';
import '../control/disturbance.dart';
import '../control/pid.dart';

/// シミュレーション全体を管理するクラス
class Simulator {
  // 履歴上限（メモリ/パフォーマンス保護用）
  final int maxHistoryLength;
  // 安全ガード（発散防止の上限）
  final double maxOutputAbs;
  final double maxControlInputAbs;
  // 制御系のコンポーネント
  late PlantModel plant;
  late PIDController pidController;
  Disturbance? disturbance;

  // プラント切替（1次/2次）
  bool _useSecondOrderPlant = false;

  // 目標値
  double targetValue = 1.0;

  // シミュレーションのステップ数
  int stepCount = 0;

  // データ履歴（グラフ表示用）
  List<double> historyTarget = [];
  List<double> historyOutput = [];
  List<double> historyControl = [];

  // 制御入力の保持（UI表示用）
  double _controlInput = 0.0;

  // 発散検知（制限超過でシミュレーションを停止）
  bool _halted = false;

  /// コンストラクタ
  Simulator({
    this.maxHistoryLength = 5000,
    this.maxOutputAbs = 10.0,
    this.maxControlInputAbs = 10.0,
  }) {
    plant = Plant(a: 0.8, b: 0.5);
    pidController = _createFirstOrderDefaultPid();
    disturbance = Disturbance(type: DisturbanceType.none);
  }

  // === ゲッター ===

  /// プラント出力を取得
  double get plantOutput => plant.output;

  /// 制御入力を取得
  double get controlInput => _controlInput;

  /// 発散検知フラグ（制限値超過で true）
  bool get isHalted => _halted;

  // === 外乱のアクセサ ===
  DisturbanceType get disturbanceType =>
      disturbance?.type ?? DisturbanceType.none;
  void setDisturbanceType(DisturbanceType type) {
    disturbance = _createDefaultDisturbance(type);
  }

  Disturbance _createDefaultDisturbance(DisturbanceType type) {
    switch (type) {
      case DisturbanceType.none:
        return Disturbance(type: DisturbanceType.none);
      case DisturbanceType.step:
        return Disturbance(
          type: DisturbanceType.step,
          amplitude: 0.2,
          startStep: 50,
        );
      case DisturbanceType.impulse:
        return Disturbance(
          type: DisturbanceType.impulse,
          amplitude: 0.5,
          startStep: 30,
        );
      case DisturbanceType.sinusoid:
        return Disturbance(
          type: DisturbanceType.sinusoid,
          amplitude: 0.2,
          omega: 0.2,
          phase: 0.0,
        );
      case DisturbanceType.noise:
        return Disturbance(
          type: DisturbanceType.noise,
          noiseStdDev: 0.05,
          noiseSeed: 42,
        );
    }
  }

  // === プラントパラメータのアクセサ ===

  // 1次プラント用パラメータ（UI互換のため既存API維持）
  double get plantParamA => plant is Plant ? (plant as Plant).a : 0.0;
  set plantParamA(double value) {
    if (plant is Plant) {
      (plant as Plant).a = value;
    }
  }

  double get plantParamB => plant is Plant ? (plant as Plant).b : 0.0;
  set plantParamB(double value) {
    if (plant is Plant) {
      (plant as Plant).b = value;
    }
  }

  // 2次プラント用パラメータ（UIで切替表示用）
  double get plantParamA1 =>
      plant is SecondOrderPlant ? (plant as SecondOrderPlant).a1 : 0.0;
  set plantParamA1(double value) {
    if (plant is SecondOrderPlant) {
      (plant as SecondOrderPlant).a1 = value;
    }
  }

  double get plantParamA2 =>
      plant is SecondOrderPlant ? (plant as SecondOrderPlant).a2 : 0.0;
  set plantParamA2(double value) {
    if (plant is SecondOrderPlant) {
      (plant as SecondOrderPlant).a2 = value;
    }
  }

  double get plantParamB1 =>
      plant is SecondOrderPlant ? (plant as SecondOrderPlant).b1 : 0.0;
  set plantParamB1(double value) {
    if (plant is SecondOrderPlant) {
      (plant as SecondOrderPlant).b1 = value;
    }
  }

  double get plantParamB2 =>
      plant is SecondOrderPlant ? (plant as SecondOrderPlant).b2 : 0.0;
  set plantParamB2(double value) {
    if (plant is SecondOrderPlant) {
      (plant as SecondOrderPlant).b2 = value;
    }
  }

  bool get isSecondOrderPlant => _useSecondOrderPlant;
  void setPlantOrder({required bool useSecondOrder}) {
    _useSecondOrderPlant = useSecondOrder;
    // プラント差し替え（状態はリセットする）
    if (_useSecondOrderPlant) {
      plant = SecondOrderPlant();
      pidController = _createSecondOrderDefaultPid();
    } else {
      plant = Plant(a: 0.8, b: 0.5);
      pidController = _createFirstOrderDefaultPid();
    }
    // 既存履歴はクリア（整合性のため）
    reset();
  }

  // === PIDゲインのアクセサ ===

  double get pidKp => pidController.kp;
  set pidKp(double value) => pidController.kp = value;

  double get pidKi => pidController.ki;
  set pidKi(double value) => pidController.ki = value;

  double get pidKd => pidController.kd;
  set pidKd(double value) => pidController.kd = value;

  /// シミュレーションを1ステップ進める
  void step() {
    if (_halted) return;

    // 誤差を計算
    final error = targetValue - plant.output;

    // PID制御器で制御入力を計算
    _controlInput = pidController.compute(error);

    // 制御入力が安全上限を超えたら停止（プラント更新前に中断）
    if (_controlInput.abs() > maxControlInputAbs) {
      _halted = true;
      return;
    }

    // プラントを更新
    final d = disturbance?.next() ?? 0.0; // 入力外乱を加算（最小統合）
    plant.step(_controlInput + d);

    // 出力が安全上限を超えたら停止
    if (plant.output.abs() > maxOutputAbs) {
      _halted = true;
    }

    // データ履歴に追加
    historyTarget.add(targetValue);
    historyOutput.add(_clampToLimit(plant.output, maxOutputAbs));
    historyControl.add(_clampToLimit(_controlInput, maxControlInputAbs));

    // 履歴が大きくなりすぎないようにトリミング（最大 maxHistoryLength）
    if (historyTarget.length > maxHistoryLength) {
      historyTarget.removeAt(0);
      historyOutput.removeAt(0);
      historyControl.removeAt(0);
    }

    stepCount++;
  }

  /// シミュレーションをリセット
  void reset() {
    plant.reset();
    pidController.reset();
    _controlInput = 0.0;
    _halted = false;
    stepCount = 0;
    historyTarget.clear();
    historyOutput.clear();
    historyControl.clear();
  }

  PIDController _createFirstOrderDefaultPid() {
    // 1次プラント向けの標準ゲイン
    return PIDController(kp: 0.3, ki: 0.1, kd: 0.1);
  }

  PIDController _createSecondOrderDefaultPid() {
    // 2次プラントはより抑えめのゲインで初期化（発散防止）
    return PIDController(kp: 0.12, ki: 0.02, kd: 0.04);
  }

  double _clampToLimit(double value, double limit) {
    if (limit <= 0) return value;
    if (value > limit) return limit;
    if (value < -limit) return -limit;
    return value;
  }

  /// 現在の状態を取得（デバッグ用）
  @override
  String toString() {
    return 'Step: $stepCount, Target: ${targetValue.toStringAsFixed(2)}, '
        'Output: ${plant.output.toStringAsFixed(2)}, '
        'Control: ${_controlInput.toStringAsFixed(2)}';
  }
}
