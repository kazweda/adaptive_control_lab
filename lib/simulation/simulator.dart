import 'package:flutter/foundation.dart';

import '../control/plant.dart';
import '../control/second_order_plant.dart';
import '../control/plant_model.dart';
import '../control/disturbance.dart';
import '../control/rls.dart';
import '../control/str.dart';
import 'disturbance_manager.dart';
import 'history_manager.dart';
import 'pid_manager.dart';
import 'str_manager.dart';

// DisturbancePreset はコンポーネント外から参照されるため export
export 'disturbance_manager.dart' show DisturbancePreset;

/// シミュレーション全体を管理するクラス
class Simulator {
  // 履歴上限（メモリ/パフォーマンス保護用）
  final int maxHistoryLength;
  // シミュレーション最大ステップ数
  final int maxSteps;
  // 安全ガード（発散防止の上限）
  final double maxOutputAbs;
  final double maxControlInputAbs;
  // RLS ウォームアップ期間（初期推定値の信頼度保持用）
  final int rlsWarmupSteps;
  // 制御系のコンポーネント
  late PlantModel plant;
  late PIDManager _pidMgr;
  late DisturbanceManager _distMgr;
  late HistoryManager _historyMgr;

  late StrManager _strMgr;

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
    this.maxHistoryLength = 1000,
    this.maxSteps = 1000,
    this.maxOutputAbs = 10.0,
    this.maxControlInputAbs = 10.0,
    this.rlsWarmupSteps = 10,
  }) {
    plant = Plant(a: 0.8, b: 0.5);
    _pidMgr = PIDManager(PIDManager.createFirstOrderDefault());
    _distMgr = DisturbanceManager();
    _historyMgr = HistoryManager(maxLength: maxHistoryLength);
    _strMgr = StrManager(useSecondOrderPlant: _useSecondOrderPlant);
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
  List<double> get historyPredictedOutput => _historyMgr.predictedOutput;
  List<double> get historyResidual => _historyMgr.residual;
  List<double> get historyEstimatedA => _historyMgr.estimatedA;
  List<double> get historyEstimatedB => _historyMgr.estimatedB;
  List<double> get historyEstimatedA1 => _historyMgr.estimatedA1;
  List<double> get historyEstimatedA2 => _historyMgr.estimatedA2;
  List<double> get historyEstimatedB1 => _historyMgr.estimatedB1;
  List<double> get historyEstimatedB2 => _historyMgr.estimatedB2;
  List<double> get historyActualA => _historyMgr.actualA;
  List<double> get historyActualB => _historyMgr.actualB;
  List<double> get historyActualA1 => _historyMgr.actualA1;
  List<double> get historyActualA2 => _historyMgr.actualA2;
  List<double> get historyActualB1 => _historyMgr.actualB1;
  List<double> get historyActualB2 => _historyMgr.actualB2;

  // === RLS推定値のゲッター ===
  bool get rlsEnabled => _strMgr.rlsEnabled;
  double get rlsLambda => _strMgr.rlsLambda;
  bool get strEnabled => _strMgr.strEnabled;
  double get strTargetPole1 => _strMgr.strTargetPole1;
  double get strTargetPole2 => _strMgr.strTargetPole2;
  RLS? get rls => _strMgr.rls;
  STR? get str => _strMgr.str;

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
    // RLS/STRインスタンスも再生成（パラメータ数に応じて）
    _strMgr.updatePlantOrder(_useSecondOrderPlant);
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

    if (strEnabled && str != null && stepCount < 5) {
      if (_useSecondOrderPlant) {
        final p = str!.rls;
        debugPrint(
          'step=$stepCount '
          'y=${plant.output.toStringAsFixed(3)} '
          'u=${_controlInput.toStringAsFixed(3)} '
          'a1_est=${p.estimatedA1.toStringAsFixed(4)} '
          'a2_est=${p.estimatedA2.toStringAsFixed(4)} '
          'b1_est=${p.estimatedB1.toStringAsFixed(4)} '
          'b2_est=${p.estimatedB2.toStringAsFixed(4)}',
        );
      } else {
        debugPrint(
          'step=$stepCount '
          'y=${plant.output.toStringAsFixed(3)} '
          'u=${_controlInput.toStringAsFixed(3)} '
          'a_est=${str!.rls.estimatedA.toStringAsFixed(4)} '
          'b_est=${str!.rls.estimatedB.toStringAsFixed(4)}',
        );
      }
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
    double? prevPrevOutput;
    double? prevPrevInput;
    if (_useSecondOrderPlant) {
      final p = plant as SecondOrderPlant;
      prevPrevOutput = p.previousOutput; // y(k-1)
      prevPrevInput = p.previousInput; // u(k-1)
    }

    // 推定器が有効な場合は予測値を計算（RLS更新前の推定値を使用）
    double? predicted;
    List<double>? phi;
    final bool hasEstimator =
        (strEnabled && str != null) || (rlsEnabled && rls != null);

    if (hasEstimator) {
      if (_useSecondOrderPlant) {
        phi = [
          prevOutput,
          prevPrevOutput ?? 0.0,
          prevInput,
          prevPrevInput ?? 0.0,
        ];
        final a1 = strEnabled && str != null
            ? str!.estimatedA1
            : (rlsEnabled && rls != null ? rls!.estimatedA1 : 0.0);
        final a2 = strEnabled && str != null
            ? str!.estimatedA2
            : (rlsEnabled && rls != null ? rls!.estimatedA2 : 0.0);
        final b1 = strEnabled && str != null
            ? str!.estimatedB1
            : (rlsEnabled && rls != null ? rls!.estimatedB1 : 0.0);
        final b2 = strEnabled && str != null
            ? str!.estimatedB2
            : (rlsEnabled && rls != null ? rls!.estimatedB2 : 0.0);
        predicted =
            a1 * prevOutput +
            a2 * (prevPrevOutput ?? 0.0) +
            b1 * prevInput +
            b2 * (prevPrevInput ?? 0.0);
      } else {
        phi = [prevOutput, prevInput];
        final a = strEnabled && str != null
            ? str!.estimatedA
            : (rlsEnabled && rls != null ? rls!.estimatedA : 0.0);
        final b = strEnabled && str != null
            ? str!.estimatedB
            : (rlsEnabled && rls != null ? rls!.estimatedB : 0.0);
        predicted = a * prevOutput + b * prevInput;
      }
    }

    // プラントを更新
    final d = _distMgr.getNext(); // 外乱マネージャーから外乱値を取得
    plant.step(_controlInput + d);

    if (predicted != null) {
      final residual = plant.output - predicted;
      _historyMgr.addResidual(
        predictedValue: predicted,
        residualValue: residual,
      );
    }

    // RLS更新（STR有効時はstr.rls、無効時はスタンドアロンrls）
    // ウォームアップ期間（最初のN ステップ）はRLS更新をスキップして、
    // initialThetaへの信頼度を保つ
    if (stepCount >= rlsWarmupSteps && phi != null) {
      if (strEnabled && str != null) {
        // STR有効時：STR内部のRLSを更新
        str!.rls.update(phi, plant.output);
      } else if (rlsEnabled && rls != null) {
        // RLS単独有効時：スタンドアロンRLSを更新
        rls!.update(phi, plant.output);
      }
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

    // プラント真値の履歴を保持（途中変更の可視化用）
    if (_useSecondOrderPlant) {
      _historyMgr.addActualSecondOrder(
        a1: plantParamA1,
        a2: plantParamA2,
        b1: plantParamB1,
        b2: plantParamB2,
      );
    } else {
      _historyMgr.addActualFirstOrder(a: plantParamA, b: plantParamB);
    }

    // RLS推定値履歴に追加
    if (strEnabled && str != null) {
      if (_useSecondOrderPlant) {
        _historyMgr.addSecondOrderEstimates(
          a1: str!.estimatedA1,
          a2: str!.estimatedA2,
          b1: str!.estimatedB1,
          b2: str!.estimatedB2,
        );
      } else {
        _historyMgr.addFirstOrderEstimates(
          a: str!.estimatedA,
          b: str!.estimatedB,
        );
      }
    } else if (rlsEnabled && rls != null) {
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

    // ステップ数上限に達したら停止
    if (stepCount >= maxSteps) {
      _halted = true;
    }
  }

  /// シミュレーションをリセット
  /// STR/RLS の有効状態と設定値は保持され、ステップカウントと履歴のみリセット
  void reset() {
    plant.reset();
    _pidMgr.reset();
    _distMgr.reset();
    _strMgr.resetControllers();
    _controlInput = 0.0;
    _halted = false;
    stepCount = 0;
    _historyMgr.clearAll();
  }

  /// RLS有効化/無効化（UIからの切替）
  void setRlsEnabled(bool enabled) {
    _strMgr.setRlsEnabled(enabled);
    if (!enabled) {
      // RLS無効時は推定履歴もクリア
      _historyMgr.clearRlsEstimates();
    }
  }

  /// 忘却係数を変更（RLSが有効な場合のみ適用）
  void setRlsLambda(double lambda) {
    _strMgr.setRlsLambda(lambda);
  }

  /// STR有効化/無効化（UIからの切替）
  void setStrEnabled(bool enabled) {
    _strMgr.setStrEnabled(enabled);
    if (!enabled) {
      // STR無効時は推定履歴もクリア
      _historyMgr.clearRlsEstimates();
    }
  }

  /// STRの所望の極を変更
  void setStrTargetPoles(double p1, double p2) {
    _strMgr.setStrTargetPoles(p1, p2);
  }

  /// STRのバタワース極を設定
  void setStrTargetPolesButterworth(double bandwidth) {
    _strMgr.setStrTargetPolesButterworth(bandwidth);
  }

  /// 現在の状態を取得（デバッグ用）
  @override
  String toString() {
    return 'Step: $stepCount, Target: ${targetValue.toStringAsFixed(2)}, '
        'Output: ${plant.output.toStringAsFixed(2)}, '
        'Control: ${_controlInput.toStringAsFixed(2)}';
  }
}
