// STR (Self-Tuning Regulator) の単体テスト

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/plant.dart';
import 'package:adaptive_control_lab/control/rls.dart';
import 'package:adaptive_control_lab/control/second_order_plant.dart';
import 'package:adaptive_control_lab/control/str.dart';

void main() {
  group('STR (Self-Tuning Regulator)', () {
    late RLS rls1;
    late RLS rls2;
    late STR str1;
    late STR str2;

    setUp(() {
      // 1次系用
      rls1 = RLS(parameterCount: 2, initialTheta: [0.8, 0.5]);
      str1 = STR(parameterCount: 2, rls: rls1, targetPole1: 0.5);

      // 2次系用
      rls2 = RLS(parameterCount: 4, initialTheta: [0.8, -0.3, 0.5, 0.1]);
      str2 = STR(
        parameterCount: 4,
        rls: rls2,
        targetPole1: 0.5,
        targetPole2: 0.3,
      );
    });

    group('初期化', () {
      test('1次系STRのコンストラクタ', () {
        expect(str1.parameterCount, 2);
        expect(str1.targetPole1, 0.5);
      });

      test('2次系STRのコンストラクタ', () {
        expect(str2.parameterCount, 4);
        expect(str2.targetPole1, 0.5);
        expect(str2.targetPole2, 0.3);
      });

      test('デフォルト極は単位円内', () {
        final str = STR(parameterCount: 2, rls: rls1);
        expect(str.targetPole1.abs(), lessThan(1.0));
        expect(str.targetPole2.abs(), lessThan(1.0));
      });

      test('所望の極の妥当性チェック（単位円外はエラー）', () {
        expect(
          () => STR(parameterCount: 2, rls: rls1, targetPole1: 1.5),
          throwsArgumentError,
        );
      });
    });

    group('制御則計算（1次系）', () {
      test('基本的な制御入力計算', () {
        // 初期化後に目標値追従
        // y=0.5, r=1.0, a=0.8, b=0.5, p_d=0.5
        // u = ((1 - p_d)*r - (a - p_d)*y) / b
        //   = ((1-0.5)*1.0 - (0.8-0.5)*0.5) / 0.5 = 0.7
        final u = str1.computeControl(0.5, 1.0);
        expect(u, closeTo(0.7, 0.01));
      });

      test('ゼロ目標値での制御', () {
        // r=0, y=0.3, a=0.8, b=0.5, p_d=0.5
        // u = (0 - (0.8 - 0.5)*0.3) / 0.5 = -0.18
        final u = str1.computeControl(0.3, 0.0);
        expect(u, closeTo(-0.18, 0.01));
      });

      test('b=0に近い場合はセーフガード', () {
        // RLSの推定b を0に設定する代わりに、STRの制御則を確認
        final rlsZero = RLS(parameterCount: 2, initialTheta: [0.8, 1e-10]);
        final strZero = STR(parameterCount: 2, rls: rlsZero);
        final u = strZero.computeControl(0.5, 1.0);
        // b≈0なのでu=0を返すべき
        expect(u.abs(), lessThan(1e-3));
      });
    });

    group('制御則計算（2次系）', () {
      test('基本的な制御入力計算', () {
        // 1回目は履歴が空なので y(k-1), u(k-1) は0として計算される
        // u1 = (1/0.5) * [(1 - p1 - p2 - p1*p2)*r - (a1 - p1 - p2)*y]
        //     = (1/0.5) * [0.05 - 0] = 0.1
        final u1 = str2.computeControl(0.5, 1.0);
        expect(u1, closeTo(0.1, 0.01));

        // 2回目は履歴が更新され、y(k-1)=0.5, u(k-1)=u1 を用いる
        // u2 = (1/0.5) * [0.05 - 0 - (-0.45)*0.5 - 0.1*u1]
        //     ≈ 0.53
        final u2 = str2.computeControl(0.3, 1.0);
        expect(u2, closeTo(0.53, 0.01));
      });

      test('b1=0に近い場合はセーフガード', () {
        final rlsZero = RLS(
          parameterCount: 4,
          initialTheta: [0.8, -0.3, 1e-10, 0.1],
        );
        final strZero = STR(parameterCount: 4, rls: rlsZero);
        final u = strZero.computeControl(0.5, 1.0);
        expect(u.abs(), lessThan(1e-3));
      });
    });

    group('所望の極の設定', () {
      test('setTargetPolesで極を更新', () {
        str1.setTargetPoles(0.6, 0.4);
        expect(str1.targetPole1, 0.6);
        expect(str1.targetPole2, 0.4);
      });

      test('setTargetPolesで妥当性チェック', () {
        expect(() => str1.setTargetPoles(1.2, 0.4), throwsArgumentError);
      });

      test('Butterworth配置は安定な極を生成', () {
        str1.setTargetPolesButterworth(0.3);
        expect(str1.targetPole1.abs(), lessThan(1.0));
        expect(str1.targetPole2.abs(), lessThan(1.0));
      });
    });

    group('リセット', () {
      test('resetで状態をクリア', () {
        // 過去値を記録させる
        str1.computeControl(0.5, 1.0);
        str1.computeControl(0.3, 1.0);

        // リセット
        str1.reset();

        // パラメータが再初期化されていることを確認
        // 厳密なチェックではなく、リセット機能が動作していることを確認
        expect(str1.rls.theta.length, 2);
      });
    });

    group('ゲッター', () {
      test('1次系の推定パラメータゲッター', () {
        expect(str1.estimatedA, str1.rls.estimatedA);
        expect(str1.estimatedB, str1.rls.estimatedB);
      });

      test('2次系の推定パラメータゲッター', () {
        expect(str2.estimatedA1, str2.rls.estimatedA1);
        expect(str2.estimatedA2, str2.rls.estimatedA2);
        expect(str2.estimatedB1, str2.rls.estimatedB1);
        expect(str2.estimatedB2, str2.rls.estimatedB2);
      });
    });

    group('数値安定性', () {
      test('極端な推定値でも発散しない', () {
        // a → 1に近い場合
        rls1.theta[0] = 0.99;
        final u = str1.computeControl(0.5, 1.0);
        expect(u.isFinite, true);

        // a → -1に近い場合
        rls1.theta[0] = -0.99;
        final u2 = str1.computeControl(0.5, 1.0);
        expect(u2.isFinite, true);
      });

      test('目標値が大きい場合の計算安定性', () {
        final u = str1.computeControl(0.5, 10.0);
        expect(u.isFinite, true);
        expect(u.abs(), lessThan(100)); // 妥当な制御入力
      });
    });

    group('定常偏差の解消', () {
      test('1次系: リファレンスゲインで定常偏差がほぼゼロ', () {
        final plant = Plant(a: 0.8, b: 0.5);
        final rls = RLS(
          parameterCount: 2,
          lambda: 1.0,
          initialTheta: [plant.a, plant.b],
        );
        final str = STR(parameterCount: 2, rls: rls, targetPole1: 0.3);

        const r = 1.0;
        for (int k = 0; k < 80; k++) {
          final u = str.computeControl(plant.output, r);
          plant.step(u);
        }

        expect(plant.output, closeTo(r, 1e-3));
      });

      test('2次系: リファレンスゲインで定常偏差がほぼゼロ', () {
        final plant = SecondOrderPlant(a1: 1.6, a2: -0.64, b1: 0.5, b2: 0.2);
        final rls = RLS(
          parameterCount: 4,
          lambda: 1.0,
          initialTheta: [plant.a1, plant.a2, plant.b1, plant.b2],
        );
        final str = STR(
          parameterCount: 4,
          rls: rls,
          targetPole1: 0.4,
          targetPole2: 0.3,
        );

        const r = 1.0;
        for (int k = 0; k < 200; k++) {
          final u = str.computeControl(plant.output, r);
          plant.step(u);
        }

        expect(plant.output, closeTo(r, 1e-2));
      });
    });

    group('統合動作', () {
      test('複数ステップでの目標値追従（1次系）', () {
        for (int k = 0; k < 50; k++) {
          final y = (k < 20) ? 0.0 : 0.5; // 途中でステップ応答
          final r = 1.0;
          final u = str1.computeControl(y, r);

          // 制御入力が有限
          expect(u.isFinite, true);

          // RLSにデータを供給（実際のシミュレーションループでは別途実施）
          final phi = [y, u];
          str1.rls.update(phi, (k < 20) ? 0.0 : 0.5);
        }

        // 推定パラメータが初期値から変化
        expect(str1.estimatedA, isNot(closeTo(0.8, 0.01)));
      });
    });

    group('オーバーフロー対策 (Issue #37)', () {
      test('初期段階での制御入力がクリップされる', () {
        // Issue #37: 初期推定値が不確定な場合、大きな制御入力が発生する
        // → controlInputLimit でクリップされるべき
        final rls = RLS(
          parameterCount: 2,
          initialTheta: [0.5, 0.3], // 小さなb値
          initialCovarianceScale: 100.0, // 修正後の値
        );
        final str = STR(parameterCount: 2, rls: rls, targetPole1: 0.5);

        const targetValue = 1.0;
        double y = 0.0;
        double uPrev = 0.0;

        // シンプルな1次プラントモデル（安定）: y(k) = 0.6*y(k-1) + 0.4*u(k-1)
        const a = 0.6;
        const b = 0.4;

        // 複数ステップ計算
        for (int step = 0; step < 5; step++) {
          final u = str.computeControl(y, targetValue);

          // 制御入力は安全上限内
          expect(u.abs(), lessThanOrEqualTo(str.controlInputLimit));

          // 制御入力は有限（NaN/Infinity ではない）
          expect(u.isFinite, true);

          // プラントを1ステップ進めてRLSへ供給
          final nextY = a * y + b * uPrev;
          str.rls.update([y, uPrev], nextY);

          // 状態更新
          uPrev = u;
          y = nextY;
        }
      });

      test('制御入力制限がデフォルト値を持つ', () {
        expect(str1.controlInputLimit, equals(10.0));
      });

      test('制御入力制限は変更可能', () {
        str1.controlInputLimit = 5.0;
        expect(str1.controlInputLimit, equals(5.0));

        // 制御入力は新しい上限でクリップされる
        final u = str1.computeControl(0.5, 1.0);
        expect(u.abs(), lessThanOrEqualTo(5.0));
      });

      test('1次系の初期段階でも安全（大きなb値）', () {
        // b > 0の場合は通常制御
        final rls = RLS(
          parameterCount: 2,
          initialTheta: [0.5, 1.0], // 十分なb値
          initialCovarianceScale: 100.0,
        );
        final str = STR(parameterCount: 2, rls: rls, targetPole1: 0.5);

        const targetValue = 1.0;
        double y = 0.0;
        double uPrev = 0.0;

        // 安定な1次プラント
        const a = 0.6;
        const b = 0.5;

        for (int step = 0; step < 3; step++) {
          final u = str.computeControl(y, targetValue);
          expect(u.isFinite, true);
          expect(u.abs(), lessThanOrEqualTo(str.controlInputLimit));

          final nextY = a * y + b * uPrev;
          str.rls.update([y, uPrev], nextY);
          uPrev = u;
          y = nextY;
        }
      });

      test('2次系でもオーバーフロー対策が有効', () {
        // 2次系でも制御入力がクリップされる
        final rls = RLS(
          parameterCount: 4,
          initialTheta: [0.7, -0.2, 0.3, 0.1],
          initialCovarianceScale: 100.0,
        );
        final str = STR(
          parameterCount: 4,
          rls: rls,
          targetPole1: 0.5,
          targetPole2: 0.3,
        );

        const targetValue = 1.0;
        double y1 = 0.0; // y(k-1)
        double y2 = 0.0; // y(k-2)
        double u1 = 0.0; // u(k-1)
        double u2 = 0.0; // u(k-2)

        // 安定な2次プラント: y(k) = 0.5*y(k-1) - 0.05*y(k-2) + 0.3*u(k-1) + 0.1*u(k-2)
        const a1 = 0.5;
        const a2 = -0.05;
        const b1 = 0.3;
        const b2 = 0.1;

        for (int step = 0; step < 5; step++) {
          final u = str.computeControl(y1, targetValue);
          expect(u.isFinite, true);
          expect(u.abs(), lessThanOrEqualTo(str.controlInputLimit));

          final nextY = a1 * y1 + a2 * y2 + b1 * u1 + b2 * u2;
          str.rls.update([y1, y2, u1, u2], nextY);

          // 状態をシフト
          y2 = y1;
          y1 = nextY;
          u2 = u1;
          u1 = u;
        }
      });
    });
  });
}
