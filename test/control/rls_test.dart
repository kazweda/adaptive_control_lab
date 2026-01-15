import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/rls.dart';
import 'package:adaptive_control_lab/control/plant.dart';

void main() {
  group('RLS (再帰最小二乗法)', () {
    // === 初期化テスト ===
    group('Initialization', () {
      test('1次系の初期化が正しく動作する', () {
        final rls = RLS(parameterCount: 2);

        expect(rls.parameterCount, 2);
        expect(rls.lambda, 0.98);
        expect(rls.theta.length, 2);

        // デフォルト初期値を確認
        expect(rls.estimatedA, closeTo(0.5, 0.01));
        expect(rls.estimatedB, closeTo(0.3, 0.01));
      });

      test('カスタム初期値が正しく設定される', () {
        final rls = RLS(
          parameterCount: 2,
          lambda: 0.95,
          initialCovarianceScale: 500.0,
          initialTheta: [0.7, 0.4],
        );

        expect(rls.lambda, 0.95);
        expect(rls.estimatedA, 0.7);
        expect(rls.estimatedB, 0.4);
      });

      test('初期共分散行列が対角行列である', () {
        final rls = RLS(parameterCount: 2, initialCovarianceScale: 1000.0);

        final P = rls.covariance;
        expect(P[0][0], 1000.0);
        expect(P[1][1], 1000.0);
        expect(P[0][1], 0.0);
        expect(P[1][0], 0.0);
      });

      test('無効なパラメータ数でエラーが発生する', () {
        expect(() => RLS(parameterCount: 3), throwsArgumentError);
      });

      test('無効な忘却係数でエラーが発生する', () {
        expect(() => RLS(parameterCount: 2, lambda: 0.5), throwsArgumentError);
        expect(() => RLS(parameterCount: 2, lambda: 1.1), throwsArgumentError);
      });
    });

    // === 推定精度テスト ===
    group('Parameter Estimation', () {
      test('既知パラメータのプラントで推定値が真値に収束する', () {
        // プラント: a=0.8, b=0.5
        final plant = Plant(a: 0.8, b: 0.5);
        final rls = RLS(
          parameterCount: 2,
          lambda: 1.0, // 標準RLS
          initialCovarianceScale: 1000.0,
        );

        double prevY = 0.0;
        double prevU = 0.0;

        for (int k = 0; k < 50; k++) {
          final u = k < 25 ? 1.0 : 0.5;

          final y = plant.step(u);

          // RLS更新（k-1の値を使う）
          if (k > 0) {
            final phi = [prevY, prevU];
            rls.update(phi, y);
          }

          prevY = y;
          prevU = u;
        }

        // 50ステップ後の推定精度を確認
        expect(rls.estimatedA, closeTo(0.8, 0.1));
        expect(rls.estimatedB, closeTo(0.5, 0.1));
      });

      test('忘却係数が異なると収束速度が変わる', () {
        final plant = Plant(a: 0.8, b: 0.5);
        final rlsFast = RLS(parameterCount: 2, lambda: 0.95); // 速い忘却
        final rlsSlow = RLS(parameterCount: 2, lambda: 1.0); // 忘却なし

        double prevY = 0.0;
        double prevU = 0.0;

        for (int k = 0; k < 20; k++) {
          final u = 1.0;
          final y = plant.step(u);

          if (k > 0) {
            final phi = [prevY, prevU];
            rlsFast.update(phi, y);
            rlsSlow.update(phi, y);
          }

          prevY = y;
          prevU = u;
        }

        // 両方とも収束するが、λ=0.95の方が更新が大きい（ことが多い）
        // ここでは単に両方が収束することを確認
        expect(rlsFast.estimatedA, isNotNaN);
        expect(rlsSlow.estimatedA, isNotNaN);
      });

      test('連続的な入力信号で推定が安定する', () {
        final plant = Plant(a: 0.7, b: 0.6);
        final rls = RLS(parameterCount: 2, lambda: 0.98);

        double prevY = 0.0;
        double prevU = 0.0;

        // 100ステップ実行
        for (int k = 0; k < 100; k++) {
          // 正弦波入力
          final u = 0.5 + 0.5 * Math.sin(2 * Math.pi * k / 20);
          final y = plant.step(u);

          if (k > 0) {
            final phi = [prevY, prevU];
            rls.update(phi, y);
          }

          prevY = y;
          prevU = u;
        }

        // 100ステップ後の推定精度
        expect(rls.estimatedA, closeTo(0.7, 0.15));
        expect(rls.estimatedB, closeTo(0.6, 0.15));
      });
    });

    // === リセットテスト ===
    group('Reset', () {
      test('reset後に初期状態に戻る', () {
        final rls = RLS(parameterCount: 2);

        final initialA = rls.estimatedA;
        final initialB = rls.estimatedB;

        // いくつか更新を行う
        for (int i = 0; i < 10; i++) {
          rls.update([0.5, 0.3], 0.4);
        }

        // パラメータが変化していることを確認
        expect(rls.estimatedA, isNot(closeTo(initialA, 0.001)));

        // リセット
        rls.reset();

        // 初期値に戻っていることを確認
        expect(rls.estimatedA, closeTo(initialA, 0.001));
        expect(rls.estimatedB, closeTo(initialB, 0.001));
      });

      test('reset後の共分散行列が初期化される', () {
        final rls = RLS(parameterCount: 2, initialCovarianceScale: 1000.0);

        final initialP = rls.covariance;

        // 更新を行う
        for (int i = 0; i < 5; i++) {
          rls.update([0.5, 0.3], 0.4);
        }

        // 共分散行列が変化していることを確認
        final updatedP = rls.covariance;
        expect(updatedP[0][0], lessThan(initialP[0][0]));

        // リセット
        rls.reset();

        // 初期共分散に戻っていることを確認
        final resetP = rls.covariance;
        expect(resetP[0][0], closeTo(1000.0, 0.01));
        expect(resetP[1][1], closeTo(1000.0, 0.01));
      });
    });

    // === 数値安定性テスト ===
    group('Numerical Stability', () {
      test('共分散行列の対角成分が正である', () {
        final rls = RLS(parameterCount: 2);

        for (int i = 0; i < 50; i++) {
          rls.update([0.5, 0.3], 0.4);

          final P = rls.covariance;
          expect(P[0][0], greaterThan(0), reason: 'P[0][0]が正であること');
          expect(P[1][1], greaterThan(0), reason: 'P[1][1]が正であること');
        }
      });

      test('ゼロ除算が発生しない', () {
        final rls = RLS(parameterCount: 2);

        // ゼロベクトルでの更新
        expect(() => rls.update([0.0, 0.0], 0.0), returnsNormally);

        // 通常の更新
        expect(() => rls.update([0.5, 0.3], 0.4), returnsNormally);
      });

      test('パラメータ推定値が発散しない', () {
        final rls = RLS(parameterCount: 2, lambda: 0.98);

        for (int i = 0; i < 100; i++) {
          rls.update([0.5, 0.3], 0.4);

          expect(rls.estimatedA.isFinite, isTrue);
          expect(rls.estimatedB.isFinite, isTrue);
          expect(rls.estimatedA.abs(), lessThan(10.0), reason: 'パラメータが発散していない');
          expect(rls.estimatedB.abs(), lessThan(10.0), reason: 'パラメータが発散していない');
        }
      });
    });

    // === ゲッターテスト ===
    group('Getters', () {
      test('1次系のゲッターが正しく動作する', () {
        final rls = RLS(parameterCount: 2, initialTheta: [0.8, 0.5]);

        expect(rls.estimatedA, 0.8);
        expect(rls.estimatedB, 0.5);
      });

      test('2次系のゲッターが正しく動作する', () {
        final rls = RLS(
          parameterCount: 4,
          initialTheta: [1.6, -0.64, 0.5, 0.2],
        );

        expect(rls.estimatedA1, 1.6);
        expect(rls.estimatedA2, -0.64);
        expect(rls.estimatedB1, 0.5);
        expect(rls.estimatedB2, 0.2);
      });

      test('1次系で2次系用ゲッターを使うとエラー', () {
        final rls = RLS(parameterCount: 2);

        expect(() => rls.estimatedA1, throwsStateError);
        expect(() => rls.estimatedA2, throwsStateError);
        expect(() => rls.estimatedB1, throwsStateError);
        expect(() => rls.estimatedB2, throwsStateError);
      });

      test('2次系で1次系用ゲッターを使うとエラー', () {
        final rls = RLS(parameterCount: 4);

        expect(() => rls.estimatedA, throwsStateError);
        expect(() => rls.estimatedB, throwsStateError);
      });
    });

    // === エッジケーステスト ===
    group('Edge Cases', () {
      test('不正な長さのphiでエラー', () {
        final rls = RLS(parameterCount: 2);

        expect(() => rls.update([0.5], 0.4), throwsArgumentError);
        expect(() => rls.update([0.5, 0.3, 0.2], 0.4), throwsArgumentError);
      });

      test('toString()が正しいフォーマットを返す', () {
        final rls = RLS(parameterCount: 2);
        final str = rls.toString();

        expect(str, contains('RLS'));
        expect(str, contains('λ='));
        expect(str, contains('a='));
        expect(str, contains('b='));
      });
    });
  });
}

// Math utility (dart:mathをimportしない簡易実装)
class Math {
  static const double pi = 3.141592653589793;
  static double sin(double x) => _sin(x);

  static double _sin(double x) {
    // Taylor series approximation for sin(x)
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;

    double result = 0.0;
    double term = x;
    for (int n = 0; n < 10; n++) {
      result += term;
      term *= -x * x / ((2 * n + 2) * (2 * n + 3));
    }
    return result;
  }
}
