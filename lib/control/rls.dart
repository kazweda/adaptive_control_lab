/// RLS（再帰最小二乗法）アルゴリズム
///
/// プラントパラメータをオンラインで推定する適応アルゴリズム。
/// 離散時間プラントモデル:
///   y(k) = a*y(k-1) + b*u(k-1)  (1次系)
///   または
///   y(k) = a1*y(k-1) + a2*y(k-2) + b1*u(k-1) + b2*u(k-2)  (2次系)
///
/// RLS更新式（忘却係数付き）:
///   1. 適応ゲイン: K(k) = P(k-1)*φ(k) / (λ + φ(k)^T*P(k-1)*φ(k))
///   2. パラメータ更新: θ(k) = θ(k-1) + K(k)*e(k)
///   3. 共分散更新: P(k) = (1/λ) * (P(k-1) - K(k)*φ(k)^T*P(k-1))
///
/// ここで:
///   - θ(k): パラメータ推定値 [a, b]^T (1次) または [a1, a2, b1, b2]^T (2次)
///   - φ(k): 回帰ベクトル [y(k-1), u(k-1)]^T (1次)
///   - e(k): 予測誤差 = y(k) - φ(k)^T*θ(k-1)
///   - P(k): 共分散行列（パラメータ不確実性）
///   - λ: 忘却係数 (0.9 ≤ λ ≤ 1.0)
class RLS {
  /// パラメータ数（1次系: 2, 2次系: 4）
  final int parameterCount;

  /// 忘却係数（時変プラント対応用）
  /// λ = 1.0: 標準RLS（全データを等しく扱う）
  /// λ < 1.0: 過去のデータを忘却（時変プラント対応）
  double lambda;

  /// パラメータ推定値 θ(k)
  /// 1次系: [a, b]
  /// 2次系: [a1, a2, b1, b2]
  late List<double> _theta;

  /// 共分散行列 P(k) (parameterCount × parameterCount)
  /// パラメータ推定の不確実性を表す
  /// P(k)が大きい → 不確実性が高い → 新しいデータを信じやすい
  late List<List<double>> _p;

  /// 初期共分散行列のスケール係数
  /// 大きいほど初期の学習が速い（推奨: 1000）
  final double _initialCovarianceScale;

  /// コンストラクタ
  ///
  /// [parameterCount] パラメータ数（1次: 2, 2次: 4）
  /// [lambda] 忘却係数（デフォルト: 0.98）
  /// [initialCovarianceScale] P(0)のスケール（デフォルト: 1000）
  /// [initialTheta] 初期パラメータ推定値（nullの場合は適当な初期値を使用）
  RLS({
    required this.parameterCount,
    this.lambda = 0.98,
    double initialCovarianceScale = 1000.0,
    List<double>? initialTheta,
  }) : _initialCovarianceScale = initialCovarianceScale {
    // パラメータ数の検証
    if (parameterCount != 2 && parameterCount != 4) {
      throw ArgumentError(
        'parameterCount must be 2 (first-order) or 4 (second-order)',
      );
    }

    // 忘却係数の検証
    if (lambda < 0.9 || lambda > 1.0) {
      throw ArgumentError('lambda must be in range [0.9, 1.0]');
    }

    // 初期化
    _theta = initialTheta ?? _createDefaultInitialTheta();
    _p = _createInitialCovariance();

    // 初期値の長さを検証
    if (_theta.length != parameterCount) {
      throw ArgumentError('initialTheta length must match parameterCount');
    }
  }

  /// デフォルトの初期パラメータを生成
  List<double> _createDefaultInitialTheta() {
    if (parameterCount == 2) {
      // 1次系: [a, b] = [0.5, 0.3]
      return [0.5, 0.3];
    } else {
      // 2次系: [a1, a2, b1, b2] = [1.0, -0.5, 0.4, 0.2]
      return [1.0, -0.5, 0.4, 0.2];
    }
  }

  /// 初期共分散行列を生成: P(0) = α*I
  List<List<double>> _createInitialCovariance() {
    final matrix = List.generate(
      parameterCount,
      (i) => List.generate(
        parameterCount,
        (j) => i == j ? _initialCovarianceScale : 0.0,
      ),
    );
    return matrix;
  }

  /// RLSアルゴリズムの1ステップ更新
  ///
  /// [phi] 回帰ベクトル φ(k) = [y(k-1), u(k-1), ...] (長さ parameterCount)
  /// [y] 現在の出力 y(k)
  ///
  /// 処理フロー:
  /// 1. 予測: ŷ(k) = φ(k)^T * θ(k-1)
  /// 2. 誤差: e(k) = y(k) - ŷ(k)
  /// 3. ゲイン: K(k) = P(k-1)*φ(k) / (λ + φ(k)^T*P(k-1)*φ(k))
  /// 4. パラメータ更新: θ(k) = θ(k-1) + K(k)*e(k)
  /// 5. 共分散更新: P(k) = (1/λ) * (P(k-1) - K(k)*φ(k)^T*P(k-1))
  void update(List<double> phi, double y) {
    if (phi.length != parameterCount) {
      throw ArgumentError('phi length must be $parameterCount');
    }

    // 1. 予測値を計算: ŷ(k) = φ(k)^T * θ(k-1)
    final yHat = _dotProduct(phi, _theta);

    // 2. 予測誤差を計算: e(k) = y(k) - ŷ(k)
    final error = y - yHat;

    // 3. P(k-1) * φ(k) を計算（ゲイン計算用）
    final pPhi = _matrixVectorProduct(_p, phi);

    // 4. φ(k)^T * P(k-1) * φ(k) を計算（スカラー）
    final phiTPphi = _dotProduct(phi, pPhi);

    // 5. 適応ゲインを計算: K(k) = Pphi / (λ + phiTPphi)
    final denominator = lambda + phiTPphi;
    final k = pPhi.map((val) => val / denominator).toList();

    // 6. パラメータを更新: θ(k) = θ(k-1) + K(k) * e(k)
    for (int i = 0; i < parameterCount; i++) {
      _theta[i] += k[i] * error;
    }

    // 7. 共分散行列を更新: P(k) = (1/λ) * (P(k-1) - K(k)*φ(k)^T*P(k-1))
    // K * φ^T * P を計算
    final kPhiTp = _outerProduct(k, pPhi);

    // P(k) = (1/λ) * (P(k-1) - KphiTP)
    for (int i = 0; i < parameterCount; i++) {
      for (int j = 0; j < parameterCount; j++) {
        _p[i][j] = (_p[i][j] - kPhiTp[i][j]) / lambda;
      }
    }
  }

  /// RLSの状態をリセット（初期状態に戻す）
  void reset() {
    _theta = _createDefaultInitialTheta();
    _p = _createInitialCovariance();
  }

  /// 推定パラメータを取得（コピー）
  List<double> get theta => List.from(_theta);

  /// 共分散行列を取得（コピー）
  List<List<double>> get covariance {
    return _p.map((row) => List<double>.from(row)).toList();
  }

  // === 1次系用の便利ゲッター ===

  /// 推定パラメータ a（1次系のみ）
  double get estimatedA {
    if (parameterCount != 2) {
      throw StateError('estimatedA is only available for first-order systems');
    }
    return _theta[0];
  }

  /// 推定パラメータ b（1次系のみ）
  double get estimatedB {
    if (parameterCount != 2) {
      throw StateError('estimatedB is only available for first-order systems');
    }
    return _theta[1];
  }

  // === 2次系用の便利ゲッター ===

  /// 推定パラメータ a1（2次系のみ）
  double get estimatedA1 {
    if (parameterCount != 4) {
      throw StateError(
        'estimatedA1 is only available for second-order systems',
      );
    }
    return _theta[0];
  }

  /// 推定パラメータ a2（2次系のみ）
  double get estimatedA2 {
    if (parameterCount != 4) {
      throw StateError(
        'estimatedA2 is only available for second-order systems',
      );
    }
    return _theta[1];
  }

  /// 推定パラメータ b1（2次系のみ）
  double get estimatedB1 {
    if (parameterCount != 4) {
      throw StateError(
        'estimatedB1 is only available for second-order systems',
      );
    }
    return _theta[2];
  }

  /// 推定パラメータ b2（2次系のみ）
  double get estimatedB2 {
    if (parameterCount != 4) {
      throw StateError(
        'estimatedB2 is only available for second-order systems',
      );
    }
    return _theta[3];
  }

  // === 内部ヘルパーメソッド（ベクトル/行列演算） ===

  /// ベクトルの内積: a^T * b
  double _dotProduct(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  /// 行列とベクトルの積: A * v
  List<double> _matrixVectorProduct(List<List<double>> a, List<double> v) {
    final result = List<double>.filled(a.length, 0.0);
    for (int i = 0; i < a.length; i++) {
      result[i] = _dotProduct(a[i], v);
    }
    return result;
  }

  /// ベクトルの外積: a * b^T （行列を返す）
  List<List<double>> _outerProduct(List<double> a, List<double> b) {
    final result = List.generate(
      a.length,
      (i) => List.generate(b.length, (j) => a[i] * b[j]),
    );
    return result;
  }

  /// デバッグ用の文字列表現
  @override
  String toString() {
    final params = parameterCount == 2
        ? 'a=${_theta[0].toStringAsFixed(3)}, b=${_theta[1].toStringAsFixed(3)}'
        : 'a1=${_theta[0].toStringAsFixed(3)}, a2=${_theta[1].toStringAsFixed(3)}, '
              'b1=${_theta[2].toStringAsFixed(3)}, b2=${_theta[3].toStringAsFixed(3)}';
    return 'RLS(λ=$lambda, $params)';
  }
}
