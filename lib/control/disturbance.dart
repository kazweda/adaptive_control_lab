import 'dart:math' as math;

/// 外乱モデル（入力に加算する外乱信号を生成）
///
/// シミュレーションで用いる代表的な外乱をサポート：
/// - none: 外乱なし
/// - step: ステップ外乱（指定ステップ以降で一定値）
/// - impulse: インパルス外乱（指定ステップで1回だけ）
/// - sinusoid: 正弦波外乱（振幅・角周波数・位相）
/// - noise: ガウス雑音（平均0、標準偏差指定）
class Disturbance {
  final DisturbanceType type;

  // 共通パラメータ
  final double amplitude; // ステップ/インパルス/正弦の振幅
  final int startStep; // ステップ/インパルス開始ステップ

  // 正弦波パラメータ
  final double omega; // 角周波数 [rad/step]
  final double phase; // 初期位相 [rad]

  // 雑音パラメータ
  final double noiseStdDev; // 標準偏差
  final int? noiseSeed; // 乱数シード（テスト再現性用）

  int _k = 0; // 現在ステップ
  double _noiseState = 0.0; // 簡易的な乱数生成の状態

  Disturbance({
    this.type = DisturbanceType.none,
    this.amplitude = 0.0,
    this.startStep = 0,
    this.omega = 0.0,
    this.phase = 0.0,
    this.noiseStdDev = 0.0,
    this.noiseSeed,
  }) {
    if (noiseSeed != null) {
      // 線形合同法の簡易初期化（テスト再現性のため）
      _noiseState = (noiseSeed! % 997).toDouble();
    }
  }

  /// 現在ステップの外乱値を返し、内部ステップを進める
  double next() {
    double value = 0.0;
    if (type == DisturbanceType.none) {
      value = 0.0;
    } else if (type == DisturbanceType.step) {
      value = _k >= startStep ? amplitude : 0.0;
    } else if (type == DisturbanceType.impulse) {
      value = _k == startStep ? amplitude : 0.0;
    } else if (type == DisturbanceType.sinusoid) {
      value = amplitude * math.sin(omega * _k + phase);
    } else if (type == DisturbanceType.noise) {
      value = noiseStdDev * _gaussianNoise();
    }

    _k++;
    return value;
  }

  /// 内部ステップをリセット
  void reset() {
    _k = 0;
  }

  double _gaussianNoise() {
    // Box–Muller 変換（擬似一様乱数から正規乱数生成）
    double u1 = _lcg() / 2147483647.0; // (0,1)
    double u2 = _lcg() / 2147483647.0; // (0,1)
    if (u1 <= 1e-12) u1 = 1e-12; // log(0) 回避
    final r = math.sqrt(-2.0 * math.log(u1));
    final theta = 2.0 * math.pi * u2;
    return r * math.cos(theta); // 平均0、分散1の乱数
  }

  int _lcg() {
    // 32bit LCG: X_{n+1} = (a*X_n + c) mod m
    const int a = 1103515245;
    const int c = 12345;
    const int m = 1 << 31;
    _noiseState = ((a * _noiseState + c) % m).toDouble();
    return _noiseState.toInt();
  }
}

enum DisturbanceType { none, step, impulse, sinusoid, noise }
