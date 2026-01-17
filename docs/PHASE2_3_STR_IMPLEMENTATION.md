# STR (Self-Tuning Regulator) 実装仕様書

## 概要

Self-Tuning Regulatorは、Recursive Least Squares (RLS) によるオンライン同定と、同定されたパラメータに基づく制御則で、時変プラントに自動的に適応する適応制御器である。

## 理論背景

### 1. ARXモデル（同定モデル）

離散時間ARX（AutoRegressive with eXogenous input）モデル：

$$y(k) = a_1 y(k-1) + a_2 y(k-2) + b_1 u(k-1) + b_2 u(k-2) + e(k)$$

または1次系：

$$y(k) = a \cdot y(k-1) + b \cdot u(k-1) + e(k)$$

ここで、$e(k)$ はモデル化誤差（ホワイトノイズと仮定）。

### 2. パラメータ同定（RLS）

RLS アルゴリズムで、各時刻 $k$ にパラメータベクトル $\theta(k)$ を推定：

$$\theta(k) = [\hat a_1, \hat a_2, \hat b_1, \hat b_2]^T$$

実装済みの `RLS` クラスを使用。

### 3. 制御則（極配置法）

同定パラメータに基づいて、閉ループシステムの極を所望の位置に配置。

#### 1次プラント場合

$$y(k) = a \cdot y(k-1) + b \cdot u(k-1)$$

所望の極: $p_d \in (0, 1)$（安定・減衰）

フィードバック則：

$$u(k) = -\frac{1}{\hat b}((\hat a - p_d) y(k) - r(k))$$

ここで、$r(k)$ は目標値。整理すると：

$$u(k) = -\frac{\hat a - p_d}{\hat b} y(k) + \frac{1}{\hat b} r(k)$$

#### 2次プラント場合

$$y(k) = \hat a_1 y(k-1) + \hat a_2 y(k-2) + \hat b_1 u(k-1) + \hat b_2 u(k-2)$$

所望の極: $p_1, p_2 \in (0, 1)$

特性多項式：

$$A_c(z) = (z - p_1)(z - p_2) = z^2 - (p_1 + p_2)z + p_1 p_2$$

制御則（Åström-Wittenmark法）：

$$B(z) u(k) = r(k) - A_c(z) y(k)$$

ここで $B(z) = \hat b_1 + \hat b_2 z^{-1}$。

展開：

$$\hat b_1 u(k) + \hat b_2 u(k-1) = r(k) - (\hat a_1 - p_1 - p_2) y(k) - (\hat a_2 - p_1 p_2) y(k-1)$$

$$u(k) = \frac{1}{\hat b_1} \left[ r(k) - (\hat a_1 - p_1 - p_2) y(k) - (\hat a_2 - p_1 p_2) y(k-1) - \hat b_2 u(k-1) \right]$$

## 実装設計

### クラス: `STR`

```dart
class STR {
  final int parameterCount;          // プラント次数に応じて決定（1次: 2, 2次: 4）
  final RLS rls;                     // パラメータ同定用RLS
  final double targetPole1;          // 所望の極1（1次・2次共通）
  final double targetPole2;          // 所望の極2（2次のみ）
  
  List<double> _previousOutput = []; // y(k-1), y(k-2)など必要な過去値
  List<double> _previousInput = [];  // u(k-1), u(k-2)など必要な過去値
  
  STR({
    required this.parameterCount,
    required this.rls,
    this.targetPole1 = 0.5,           // デフォルト
    this.targetPole2 = 0.3,           // デフォルト（2次用）
  });
  
  /// 現在のステップでの制御入力を計算
  double computeControl(double y, double r) {
    // 推定パラメータ取得
    final a1 = rls.estimatedA1;
    final a2 = rls.estimatedA2;
    final b1 = rls.estimatedB1;
    final b2 = rls.estimatedB2;
    
    double u;
    
    if (parameterCount == 2) {
      // 1次プラント
      u = _computeControl1st(a1, b1, y, r);
    } else if (parameterCount == 4) {
      // 2次プラント
      u = _computeControl2nd(a1, a2, b1, b2, y, r);
    } else {
      throw ArgumentError('Unsupported parameter count: $parameterCount');
    }
    
    // 過去値を更新
    _updateHistory(y, u);
    
    return u;
  }
  
  /// 1次プラント用制御則
  double _computeControl1st(double a, double b, double y, double r) {
    if (b.abs() < 1e-8) return 0.0; // b=0の場合は安全のため0を返す
    return (r - (a - targetPole1) * y) / b;
  }
  
  /// 2次プラント用制御則
  double _computeControl2nd(
    double a1, double a2, double b1, double b2, double y, double r
  ) {
    if (b1.abs() < 1e-8) return 0.0; // b1=0の場合は安全のため0を返す
    
    final coeff_a1 = a1 - targetPole1 - targetPole2;
    final coeff_a2 = a2 - targetPole1 * targetPole2;
    
    final term1 = r;
    final term2 = coeff_a1 * y;
    final term3 = coeff_a2 * (_previousOutput.isNotEmpty ? _previousOutput[0] : 0);
    final term4 = b2 * (_previousInput.isNotEmpty ? _previousInput[0] : 0);
    
    return (term1 - term2 - term3 - term4) / b1;
  }
  
  /// 過去値を更新
  void _updateHistory(double y, double u) {
    _previousOutput.insert(0, y);
    if (_previousOutput.length > 2) _previousOutput.removeLast();
    
    _previousInput.insert(0, u);
    if (_previousInput.length > 2) _previousInput.removeLast();
  }
  
  /// リセット
  void reset() {
    rls.reset();
    _previousOutput.clear();
    _previousInput.clear();
  }
  
  /// ゲッター
  double get estimatedA1 => rls.estimatedA1;
  double get estimatedA2 => rls.estimatedA2;
  double get estimatedB1 => rls.estimatedB1;
  double get estimatedB2 => rls.estimatedB2;
  
  void setTargetPoles(double p1, double p2) {
    // 安定性チェック: |p| < 1
    if (p1.abs() >= 1.0 || p2.abs() >= 1.0) {
      throw ArgumentError('Target poles must be inside unit circle: |p| < 1');
    }
    targetPole1 = p1;
    targetPole2 = p2;
  }
}
```

## Simulator統合

STRモードを有効にするためのフィールドとメソッド：

```dart
class Simulator {
  bool strEnabled = false;
  STR? str;
  
  void setStrEnabled(bool enabled, {int plantOrder = 1}) {
    strEnabled = enabled;
    if (enabled) {
      _initializeSTR(plantOrder);
    }
  }
  
  void _initializeSTR(int plantOrder) {
    final paramCount = plantOrder == 1 ? 2 : 4;
    str = STR(
      parameterCount: paramCount,
      rls: RLS(parameterCount: paramCount),
      targetPole1: 0.5,
      targetPole2: 0.3,
    );
  }
  
  void step() {
    final error = targetValue - plantOutput;
    
    double controlInput;
    if (strEnabled && str != null) {
      controlInput = str!.computeControl(plantOutput, targetValue);
      // RLSに phi ベクトルを渡してパラメータ更新
      final phi = _buildPhi();
      str!.rls.update(phi, plantOutput);
    } else {
      // PID制御
      controlInput = pid.compute(error);
    }
    
    // 以下プラント更新...
  }
  
  List<double> _buildPhi() {
    if (isSecondOrderPlant) {
      return [
        plant.previousOutput,
        plant.previousPreviousOutput,
        plant.previousInput,
        plant.previousPreviousInput,
      ];
    } else {
      return [plant.previousOutput, plant.previousInput];
    }
  }
}
```

## テスト戦略

1. **STRコアロジック単体テスト**
   - 1次系での制御則計算確認
   - 2次系での制御則計算確認
   - 極安定性チェック

2. **Simulator統合テスト**
   - STR有効/無効の切替
   - プラント次数切替時のSTR再初期化
   - RLS連携確認

3. **収束性テスト**
   - 既知パラメータのプラントで目標値追従確認

## 実装スケジュール

1. STRコアロジック実装 + 単体テスト
2. Simulator統合 + 統合テスト
3. STR UI画面実装 (極配置パラメータ表示・調整)
4. PR作成・レビュー

---

**参考文献**
- Åström, K. J., & Wittenmark, B. (1995). *Adaptive Control* (2nd ed.)
- Goodwin, G. C., & Sin, K. S. (1984). *Adaptive Filtering, Prediction, and Control*
