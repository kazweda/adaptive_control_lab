/// シミュレーションデータの履歴管理クラス
///
/// 目標値、出力値、制御入力、RLS推定値の履歴を管理し、
/// 自動トリミングによるメモリ保護を提供する。
class HistoryManager {
  /// 履歴の最大長（メモリ/パフォーマンス保護用）
  final int maxLength;

  // 基本履歴（全シミュレーションで使用）
  List<double> target = [];
  List<double> output = [];
  List<double> control = [];

  // 予測値と残差（RLS/STRの診断用）
  List<double> predictedOutput = [];
  List<double> residual = [];

  // 1次プラント用のRLS推定値履歴
  List<double> estimatedA = [];
  List<double> estimatedB = [];

  // 2次プラント用のRLS推定値履歴
  List<double> estimatedA1 = [];
  List<double> estimatedA2 = [];
  List<double> estimatedB1 = [];
  List<double> estimatedB2 = [];

  // 真値のトレース（途中でプラントパラメータを変更した場合の可視化用）
  List<double> actualA = [];
  List<double> actualB = [];
  List<double> actualA1 = [];
  List<double> actualA2 = [];
  List<double> actualB1 = [];
  List<double> actualB2 = [];

  /// コンストラクタ
  HistoryManager({this.maxLength = 5000});

  /// 基本履歴（目標値、出力、制御入力）を追加
  void addStep({
    required double targetValue,
    required double outputValue,
    required double controlValue,
  }) {
    target.add(targetValue);
    output.add(outputValue);
    control.add(controlValue);

    // 自動トリミング（基本履歴のみチェック）
    if (target.length > maxLength) {
      target.removeAt(0);
      output.removeAt(0);
      control.removeAt(0);
    }
  }

  /// 予測値と残差を追加（RLS/STRの診断用）
  void addResidual({
    required double predictedValue,
    required double residualValue,
  }) {
    predictedOutput.add(predictedValue);
    residual.add(residualValue);

    if (residual.length > maxLength) {
      predictedOutput.removeAt(0);
      residual.removeAt(0);
    }
  }

  /// 1次プラント用のRLS推定値を追加
  void addFirstOrderEstimates({required double a, required double b}) {
    estimatedA.add(a);
    estimatedB.add(b);

    // 自動トリミング
    if (estimatedA.length > maxLength) {
      estimatedA.removeAt(0);
      estimatedB.removeAt(0);
    }
  }

  /// 2次プラント用のRLS推定値を追加
  void addSecondOrderEstimates({
    required double a1,
    required double a2,
    required double b1,
    required double b2,
  }) {
    estimatedA1.add(a1);
    estimatedA2.add(a2);
    estimatedB1.add(b1);
    estimatedB2.add(b2);

    // 自動トリミング
    if (estimatedA1.length > maxLength) {
      estimatedA1.removeAt(0);
      estimatedA2.removeAt(0);
      estimatedB1.removeAt(0);
      estimatedB2.removeAt(0);
    }
  }

  /// 1次プラントの真値を追加
  void addActualFirstOrder({required double a, required double b}) {
    actualA.add(a);
    actualB.add(b);

    if (actualA.length > maxLength) {
      actualA.removeAt(0);
      actualB.removeAt(0);
    }
  }

  /// 2次プラントの真値を追加
  void addActualSecondOrder({
    required double a1,
    required double a2,
    required double b1,
    required double b2,
  }) {
    actualA1.add(a1);
    actualA2.add(a2);
    actualB1.add(b1);
    actualB2.add(b2);

    if (actualA1.length > maxLength) {
      actualA1.removeAt(0);
      actualA2.removeAt(0);
      actualB1.removeAt(0);
      actualB2.removeAt(0);
    }
  }

  /// 全履歴をクリア
  void clearAll() {
    target.clear();
    output.clear();
    control.clear();
    predictedOutput.clear();
    residual.clear();
    actualA.clear();
    actualB.clear();
    actualA1.clear();
    actualA2.clear();
    actualB1.clear();
    actualB2.clear();
    clearRlsEstimates();
  }

  /// RLS推定値履歴のみクリア
  void clearRlsEstimates() {
    estimatedA.clear();
    estimatedB.clear();
    estimatedA1.clear();
    estimatedA2.clear();
    estimatedB1.clear();
    estimatedB2.clear();
    predictedOutput.clear();
    residual.clear();
  }

  /// 履歴のステップ数を取得
  int get length => target.length;

  /// デバッグ用の文字列表現
  @override
  String toString() {
    return 'HistoryManager(length: $length/$maxLength, '
        'hasRlsFirstOrder: ${estimatedA.isNotEmpty}, '
        'hasRlsSecondOrder: ${estimatedA1.isNotEmpty}, '
        'hasResidual: ${residual.isNotEmpty})';
  }
}
