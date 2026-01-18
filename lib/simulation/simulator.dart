import '../control/plant.dart';
import '../control/second_order_plant.dart';
import '../control/plant_model.dart';
import '../control/disturbance.dart';
import '../control/rls.dart';
import '../control/str.dart';
import 'disturbance_manager.dart';
import 'history_manager.dart';
import 'pid_manager.dart';

// DisturbancePreset はコンポーネント外から参照されるため export
export 'disturbance_manager.dart' show DisturbancePreset;

/// シミュレーション全体を管理するクラス
class Simulator {
  // 履歴上限（メモリ/パフォーマンス保護用）
  final int maxHistoryLength;
  // 安全ガード（発散防止の上限）
  final double maxOutputAbs;
  final double maxControlInputAbs;
  // 制御系のコンポーネント
  late PlantModel plant;
  late PIDManager _pidMgr;
  late DisturbanceManager _distMgr;
  late HistoryManager _historyMgr;

  // RLS（適応パラメータ推定）
  RLS? rls;
  bool rlsEnabled = false;
  double rlsLambda = 0.98;

  // STR（自己調整制御）
  STR? str;
  bool strEnabled = false;
  double strTargetPole1 = 0.5;
  double strTargetPole2 = 0.3;

  // プラント切替（1次/2次）
  bool _useSecondOrderPlant = false;

  // 目標値
  double targetValue = 1.0;

  // シミュレーションのステップ数
  int stepCount = 0;

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
    _pidMgr = PIDManager(PIDManager.createFirstOrderDefault());
    _distMgr = DisturbanceManager();
    _historyMgr = HistoryManager(maxLength: maxHistoryLength);
  }

  // === ゲッター ===

  /// プラント出力を取得
  double get plantOutput => plant.output;

  /// 制御入力を取得
  double get controlInput => _controlInput;

  /// 発散検知フラグ（制限値超過で true）
  bool get isHalted => _halted;

  // === 履歴アクセス用のゲッター（UI互換性維持） ===

  List<double> get historyTarget => _historyMgr.target;
  List<double> get historyOutput => _historyMgr.output;
  List<double> get historyControl => _historyMgr.control;
  List<double> get historyEstimatedA => _historyMgr.estimatedA;
  List<double> get historyEstimatedB => _historyMgr.estimatedB;
  List<double> get historyEstimatedA1 => _historyMgr.estimatedA1;
  List<double> get historyEstimatedA2 => _historyMgr.estimatedA2;
  List<double> get historyEstimatedB1 => _historyMgr.estimatedB1;
  List<double> get historyEstimatedB2 => _historyMgr.estimatedB2;

  // === RLS推定値のゲッター ===

  /// 1次プラント用の推定値（RLS/STR無効時は真値を返す）
  double get estimatedA {
    if (strEnabled && str != null) {
      return str!.estimatedA;
    }
    if (rlsEnabled && rls != null) {
      return rls!.estimatedA;
    }
    return plantParamA;
  }

  double get estimatedB {
    if (strEnabled && str != null) {
      return str!.estimatedB;
    }
    if (rlsEnabled && rls != null) {
      return rls!.estimatedB;
    }
    return plantParamB;
  }

  /// 2次プラント用の推定値（RLS/STR無効時は真値を返す）
  double get estimatedA1 {
    if (strEnabled && str != null) {
      return str!.estimatedA1;
    }
    if (rlsEnabled && rls != null) {
      return rls!.estimatedA1;
    }
    return plantParamA1;
  }

  double get estimatedA2 {
    if (strEnabled && str != null) {
      return str!.estimatedA2;
    }
    if (rlsEnabled && rls != null) {
      return rls!.estimatedA2;
    }
    return plantParamA2;
  }

  double get estimatedB1 {
    if (strEnabled && str != null) {
      return str!.estimatedB1;
    }
    if (rlsEnabled && rls != null) {
      return rls!.estimatedB1;
    }
    return plantParamB1;
  }

  double get estimatedB2 {
    if (strEnabled && str != null) {
      return str!.estimatedB2;
    }
    if (rlsEnabled && rls != null) {
      return rls!.estimatedB2;
    }
    return plantParamB2;
  }

  // === 外乱のアクセサ（API互換性を維持） ===
  DisturbanceType get disturbanceType => _distMgr.getType();
  void setDisturbanceType(DisturbanceType type) => _distMgr.setType(type);

  String get currentPresetName => _distMgr.currentPresetName;

  /// プリセット一覧を取得
  static List<DisturbancePreset> getAvailablePresets() {
    return DisturbanceManager.getAvailablePresets();
  }

  /// プリセットを適用
  void applyDisturbancePreset(String presetName) {
    _distMgr.applyPreset(presetName);
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
      _pidMgr = PIDManager(PIDManager.createSecondOrderDefault());
    } else {
      plant = Plant(a: 0.8, b: 0.5);
      _pidMgr = PIDManager(PIDManager.createFirstOrderDefault());
    }
    // RLSインスタンスも再生成（パラメータ数に応じて）
    _initializeRls();
    // STRインスタンスも再生成（パラメータ数に応じて）
    _initializeStr();
    // 既存履歴はクリア（整合性のため）
    reset();
  }

  // === PIDゲインのアクセサ（API互換性を維持） ===

  double get pidKp => _pidMgr.kp;
  set pidKp(double value) => _pidMgr.kp = value;

  double get pidKi => _pidMgr.ki;
  set pidKi(double value) => _pidMgr.ki = value;

  double get pidKd => _pidMgr.kd;
  set pidKd(double value) => _pidMgr.kd = value;

  /// シミュレーションを1ステップ進める
  void step() {
    if (_halted) return;

    // 誤差を計算
    final error = targetValue - plant.output;

    // 制御入力を計算（STR優先、その次RLS無効時はPID）
    if (strEnabled && str != null) {
      _controlInput = str!.computeControl(plant.output, targetValue);
    } else {
      // PID制御器で制御入力を計算
      _controlInput = _pidMgr.computeControl(error);
    }

    // 制御入力が安全上限を超えたら停止（プラント更新前に中断）
    if (_controlInput.abs() > maxControlInputAbs) {
      _halted = true;
      // 制御入力超過時は履歴も追加せず完全に中断
      return;
    }

    // プラント更新前の過去値を保存（RLS更新用）
    final prevOutput = plant.output;
    final prevInput = _controlInput;

    // プラントを更新
    final d = _distMgr.getNext(); // 外乱マネージャーから外乱値を取得
    plant.step(_controlInput + d);

    // RLS更新（STR有効時はstr.rls、無効時はスタンドアロンrls）
    if (strEnabled && str != null) {
      // STR有効時：STR内部のRLSを更新
      final List<double> phi;
      if (_useSecondOrderPlant) {
        final p = plant as SecondOrderPlant;
        phi = [
          prevOutput,
          p.previousPreviousOutput,
          prevInput,
          p.previousPreviousInput,
        ];
      } else {
        phi = [prevOutput, prevInput];
      }
      str!.rls.update(phi, plant.output);
    } else if (rlsEnabled && rls != null) {
      // RLS単独有効時：スタンドアロンRLSを更新
      final List<double> phi;
      if (_useSecondOrderPlant) {
        final p = plant as SecondOrderPlant;
        phi = [
          prevOutput,
          p.previousPreviousOutput,
          prevInput,
          p.previousPreviousInput,
        ];
      } else {
        phi = [prevOutput, prevInput];
      }
      rls!.update(phi, plant.output);
    }

    // stepCountをインクリメント（出力チェック前に実施）
    stepCount++;

    // 出力が安全上限を超えたら停止
    if (plant.output.abs() > maxOutputAbs) {
      _halted = true;
      // 出力超過時も履歴追加せずに中断（一貫性のため）
      return;
    }

    // データ履歴に追加（halt時は到達しない）
    _historyMgr.addStep(
      targetValue: targetValue,
      outputValue: plant.output,
      controlValue: _controlInput,
    );

    // RLS推定値履歴に追加
    if (rlsEnabled && rls != null) {
      if (_useSecondOrderPlant) {
        _historyMgr.addSecondOrderEstimates(
          a1: rls!.estimatedA1,
          a2: rls!.estimatedA2,
          b1: rls!.estimatedB1,
          b2: rls!.estimatedB2,
        );
      } else {
        _historyMgr.addFirstOrderEstimates(
          a: rls!.estimatedA,
          b: rls!.estimatedB,
        );
      }
    }
  }

  /// シミュレーションをリセット
  void reset() {
    plant.reset();
    _pidMgr.reset();
    _distMgr.reset();
    rls?.reset();
    str?.reset();
    _controlInput = 0.0;
    _halted = false;
    stepCount = 0;
    _historyMgr.clearAll();
  }

  /// RLSインスタンスを初期化（プラント次数に応じて）
  void _initializeRls() {
    if (!rlsEnabled) {
      rls = null;
      return;
    }
    final paramCount = _useSecondOrderPlant ? 4 : 2;
    rls = RLS(
      parameterCount: paramCount,
      lambda: rlsLambda,
      initialCovarianceScale: 1000.0,
    );
  }

  /// RLS有効化/無効化（UIからの切替）
  void setRlsEnabled(bool enabled) {
    rlsEnabled = enabled;
    _initializeRls();
    if (!enabled) {
      // RLS無効時は推定履歴もクリア
      _historyMgr.clearRlsEstimates();
    }
  }

  /// 忘却係数を変更（RLSが有効な場合のみ適用）
  void setRlsLambda(double lambda) {
    rlsLambda = lambda;
    if (rlsEnabled && rls != null) {
      // 忘却係数の変更はコンストラクタの検証ロジックを維持するため
      // RLSインスタンスを再生成して反映する
      _initializeRls();
    }
  }

  /// STR有効化/無効化（UIからの切替）
  void setStrEnabled(bool enabled) {
    strEnabled = enabled;
    _initializeStr();
    if (!enabled) {
      // STR無効時は推定履歴もクリア
      _historyMgr.clearRlsEstimates();
    }
  }

  /// STRの所望の極を変更
  void setStrTargetPoles(double p1, double p2) {
    strTargetPole1 = p1;
    strTargetPole2 = p2;
    if (strEnabled && str != null) {
      str!.setTargetPoles(p1, p2);
    }
  }

  /// STRインスタンスを初期化（プラント次数に応じて）
  void _initializeStr() {
    if (!strEnabled) {
      str = null;
      return;
    }
    final paramCount = _useSecondOrderPlant ? 4 : 2;
    // STRはRLS内部を持つため、新しいRLSインスタンスを作成
    final strRls = RLS(
      parameterCount: paramCount,
      lambda: rlsLambda,
      initialCovarianceScale: 1000.0,
    );
    str = STR(
      parameterCount: paramCount,
      rls: strRls,
      targetPole1: strTargetPole1,
      targetPole2: strTargetPole2,
    );
  }

  /// 現在の状態を取得（デバッグ用）
  @override
  String toString() {
    return 'Step: $stepCount, Target: ${targetValue.toStringAsFixed(2)}, '
        'Output: ${plant.output.toStringAsFixed(2)}, '
        'Control: ${_controlInput.toStringAsFixed(2)}';
  }
}
