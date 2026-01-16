import 'plant_model.dart';

/// プラントモデル（2次系）
///
/// 離散時間の2次系差分方程式：
/// y(k) = a1 * y(k-1) + a2 * y(k-2) + b1 * u(k-1) + b2 * u(k-2)
///
/// - y(k): 現在の出力
/// - a1, a2: フィードバック係数（極の位置を決める）
/// - b1, b2: 入力係数（応答の敏感さ）
/// - u(k-1), u(k-2): 過去2ステップの制御入力
class SecondOrderPlant implements PlantModel {
  // プラントパラメータ
  double a1; // y(k-1) の係数
  double a2; // y(k-2) の係数
  double b1; // u(k-1) の係数
  double b2; // u(k-2) の係数

  // 状態変数（過去の値を保持）
  double _output = 0.0; // y(k): 現在の出力
  double _prevOutput = 0.0; // y(k-1): ひとつ前の出力
  double _prevInput = 0.0; // u(k-1): ひとつ前の入力
  double _prevPrevInput = 0.0; // u(k-2): ふたつ前の入力

  /// コンストラクタ
  /// 既定値は減衰付きの安定な極（例: r=0.8, 重根）を想定
  SecondOrderPlant({
    this.a1 = 1.6,
    this.a2 = -0.64,
    this.b1 = 0.5,
    this.b2 = 0.2,
  });

  /// 現在の出力 y(k)
  @override
  double get output => _output;

  /// 前々出力 y(k-2)（RLSのphi構築用）
  double get previousPreviousOutput => _prevOutput;

  /// 前々入力 u(k-2)（RLSのphi構築用）
  double get previousPreviousInput => _prevPrevInput;

  /// プラントを1ステップ更新
  ///
  /// [input] 現在の制御入力 u(k)
  /// 戻り値：更新後のプラント出力 y(k)
  @override
  double step(double input) {
    // 過去値をローカルに保持（更新順序のため）
    final yK1 = _output; // y(k-1)
    final yK2 = _prevOutput; // y(k-2)
    final uK1 = _prevInput; // u(k-1)
    final uK2 = _prevPrevInput; // u(k-2)

    // 2次系の差分方程式を計算
    final newOutput = a1 * yK1 + a2 * yK2 + b1 * uK1 + b2 * uK2;

    // 状態更新（更新順序に注意）
    _prevOutput = yK1; // 現在の y(k-1) を y(k-2) へシフト
    _output = newOutput; // 新しい y(k)
    _prevPrevInput = _prevInput; // 入力履歴のシフト
    _prevInput = input; // u(k) を次ステップ用に保存

    return _output;
  }

  /// プラントの状態をリセット
  @override
  void reset() {
    _output = 0.0;
    _prevOutput = 0.0;
    _prevInput = 0.0;
    _prevPrevInput = 0.0;
  }

  /// デバッグ用の文字列表現
  @override
  String toString() {
    return 'SecondOrderPlant(a1: $a1, a2: $a2, b1: $b1, b2: $b2, output: '
        '${_output.toStringAsFixed(3)})';
  }
}
