/// プラント共通インターフェース
///
/// UI層とシミュレータ層から、1次/2次などの具体的なプラント実装を
/// 抽象化して扱うためのインターフェース。
abstract class PlantModel {
  /// 現在の出力 y(k)
  double get output;

  /// 1ステップ更新
  double step(double input);

  /// 状態リセット
  void reset();
}
