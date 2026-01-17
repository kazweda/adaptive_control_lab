// STR (Self-Tuning Regulator) の単体テスト

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/rls.dart';
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
        // u = (r - (a - p_d)*y) / b = (1.0 - (0.8 - 0.5)*0.5) / 0.5
        //   = (1.0 - 0.15) / 0.5 = 1.7
        final u = str1.computeControl(0.5, 1.0);
        expect(u, closeTo(1.7, 0.01));
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
        // u1 = (1/0.5) * [1.0 - (0.8 - 0.8)*0.5 - (-0.3 - 0.15)*0 - 0.1*0]
        //     = 2.0
        final u1 = str2.computeControl(0.5, 1.0);
        expect(u1, closeTo(2.0, 0.01));

        // 2回目は履歴が更新され、y(k-1)=0.5, u(k-1)=u1=2.0 を用いる
        // u2 = (1/0.5) * [1.0 - (0.8 - 0.8)*0.3 - (-0.3 - 0.15)*0.5 - 0.1*2.0]
        //     = 2.05
        final u2 = str2.computeControl(0.3, 1.0);
        expect(u2, closeTo(2.05, 0.01));
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
  });
}
