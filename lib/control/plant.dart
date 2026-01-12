/// プラントモデル（1次系）
///
/// 離散時間の1次系差分方程式：
/// y(k) = a * y(k-1) + b * u(k-1)
///
/// - y(k): 現在の出力
/// - a: フィードバック係数（慣性の強さ）
/// - b: 入力係数（応答の敏感さ）
/// - u(k-1): 前のステップの制御入力
class Plant {
  // プラントパラメータ
  double a; // フィードバック係数（大きいほど前の値が強く影響）
  double b; // 入力係数（大きいほど入力に敏感に反応）

  // 状態変数
  double _output = 0.0; // y(k): プラント出力
  double _previousInput = 0.0; // u(k-1): 前のステップの制御入力

  /// コンストラクタ
  Plant({this.a = 0.8, this.b = 0.5});

  /// プラントの出力を取得
  double get output => _output;

  /// プラントを1ステップ更新
  ///
  /// [input] 現在の制御入力 u(k)
  /// 戻り値：更新後のプラント出力 y(k)
  double step(double input) {
    // 1次系の差分方程式を計算
    _output = a * _output + b * _previousInput;

    // 次のステップのために現在の入力を保存
    _previousInput = input;

    return _output;
  }

  /// プラントの状態をリセット
  void reset() {
    _output = 0.0;
    _previousInput = 0.0;
  }

  /// デバッグ用の文字列表現
  @override
  String toString() {
    return 'Plant(a: $a, b: $b, output: ${_output.toStringAsFixed(3)})';
  }
}
