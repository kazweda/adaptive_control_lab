import '../control/plant.dart';
import '../control/pid.dart';

/// シミュレーション全体を管理するクラス
class Simulator {
  // 履歴上限（メモリ/パフォーマンス保護用）
  final int maxHistoryLength;
  // 制御系のコンポーネント
  late Plant plant;
  late PIDController pidController;

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

  /// コンストラクタ
  Simulator({this.maxHistoryLength = 5000}) {
    plant = Plant(a: 0.8, b: 0.5);
    pidController = PIDController(kp: 0.3, ki: 0.1, kd: 0.1);
  }

  // === ゲッター ===

  /// プラント出力を取得
  double get plantOutput => plant.output;

  /// 制御入力を取得
  double get controlInput => _controlInput;

  // === プラントパラメータのアクセサ ===

  double get plantParamA => plant.a;
  set plantParamA(double value) => plant.a = value;

  double get plantParamB => plant.b;
  set plantParamB(double value) => plant.b = value;

  // === PIDゲインのアクセサ ===

  double get pidKp => pidController.kp;
  set pidKp(double value) => pidController.kp = value;

  double get pidKi => pidController.ki;
  set pidKi(double value) => pidController.ki = value;

  double get pidKd => pidController.kd;
  set pidKd(double value) => pidController.kd = value;

  /// シミュレーションを1ステップ進める
  void step() {
    // 誤差を計算
    final error = targetValue - plant.output;

    // PID制御器で制御入力を計算
    _controlInput = pidController.compute(error);

    // プラントを更新
    plant.step(_controlInput);

    // データ履歴に追加
    historyTarget.add(targetValue);
    historyOutput.add(plant.output);
    historyControl.add(_controlInput);

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
    stepCount = 0;
    historyTarget.clear();
    historyOutput.clear();
    historyControl.clear();
  }

  /// 現在の状態を取得（デバッグ用）
  @override
  String toString() {
    return 'Step: $stepCount, Target: ${targetValue.toStringAsFixed(2)}, '
        'Output: ${plant.output.toStringAsFixed(2)}, '
        'Control: ${_controlInput.toStringAsFixed(2)}';
  }
}
