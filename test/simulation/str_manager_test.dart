import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/simulation/str_manager.dart';

void main() {
  group('StrManager', () {
    group('初期化', () {
      test('1次プラント用のデフォルト初期化', () {
        final mgr = StrManager(useSecondOrderPlant: false);

        expect(mgr.rlsEnabled, false);
        expect(mgr.strEnabled, false);
        expect(mgr.rls, isNull);
        expect(mgr.str, isNull);
        expect(mgr.rlsLambda, 0.995);
        expect(mgr.strTargetPole1, 0.5);
        expect(mgr.strTargetPole2, 0.3);
        expect(mgr.useSecondOrderPlant, false);
      });

      test('2次プラント用のデフォルト初期化', () {
        final mgr = StrManager(useSecondOrderPlant: true);

        expect(mgr.useSecondOrderPlant, true);
        expect(mgr.rlsEnabled, false);
        expect(mgr.strEnabled, false);
      });

      test('カスタムパラメータでの初期化', () {
        final mgr = StrManager(
          useSecondOrderPlant: true,
          rlsLambda: 0.95,
          strTargetPole1: 0.6,
          strTargetPole2: 0.4,
          initialCovarianceScale: 50.0,
        );

        expect(mgr.rlsLambda, 0.95);
        expect(mgr.strTargetPole1, 0.6);
        expect(mgr.strTargetPole2, 0.4);
      });
    });

    group('RLS有効化/無効化', () {
      test('RLS有効化：1次プラント用インスタンスが生成される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setRlsEnabled(true);

        expect(mgr.rlsEnabled, true);
        expect(mgr.rls, isNotNull);
        expect(mgr.rls!.parameterCount, 2);
      });

      test('RLS有効化：2次プラント用インスタンスが生成される', () {
        final mgr = StrManager(useSecondOrderPlant: true);
        mgr.setRlsEnabled(true);

        expect(mgr.rlsEnabled, true);
        expect(mgr.rls, isNotNull);
        expect(mgr.rls!.parameterCount, 4);
      });

      test('RLS無効化：インスタンスが削除される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setRlsEnabled(true);
        expect(mgr.rls, isNotNull);

        mgr.setRlsEnabled(false);
        expect(mgr.rlsEnabled, false);
        expect(mgr.rls, isNull);
      });
    });

    group('STR有効化/無効化', () {
      test('STR有効化：1次プラント用インスタンスが生成される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrEnabled(true);

        expect(mgr.strEnabled, true);
        expect(mgr.str, isNotNull);
        expect(mgr.str!.rls.parameterCount, 2);
      });

      test('STR有効化：2次プラント用インスタンスが生成される', () {
        final mgr = StrManager(useSecondOrderPlant: true);
        mgr.setStrEnabled(true);

        expect(mgr.strEnabled, true);
        expect(mgr.str, isNotNull);
        expect(mgr.str!.rls.parameterCount, 4);
      });

      test('STR無効化：インスタンスが削除される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrEnabled(true);
        expect(mgr.str, isNotNull);

        mgr.setStrEnabled(false);
        expect(mgr.strEnabled, false);
        expect(mgr.str, isNull);
      });
    });

    group('忘却係数の変更', () {
      test('setRlsLambda：格納値が更新される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        expect(mgr.rlsLambda, 0.995);

        mgr.setRlsLambda(0.95);
        expect(mgr.rlsLambda, 0.95);
      });

      test('RLS有効時にlambda変更：インスタンスが再生成される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setRlsEnabled(true);
        final oldRls = mgr.rls;

        mgr.setRlsLambda(0.95);
        expect(mgr.rls, isNot(same(oldRls)));
        expect(mgr.rls!.lambda, 0.95);
      });

      test('STR有効時にlambda変更：STRインスタンスが再生成される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrEnabled(true);
        final oldStr = mgr.str;

        mgr.setRlsLambda(0.90);
        expect(mgr.str, isNot(same(oldStr)));
        expect(mgr.str!.rls.lambda, 0.90);
      });

      test('RLS/STR両方無効時にlambda変更：次の有効化時に反映される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setRlsLambda(0.92);

        mgr.setRlsEnabled(true);
        expect(mgr.rls!.lambda, 0.92);

        mgr.setRlsEnabled(false);
        mgr.setStrEnabled(true);
        expect(mgr.str!.rls.lambda, 0.92);
      });
    });

    group('目標極の設定', () {
      test('setStrTargetPoles：格納値が更新される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrTargetPoles(0.7, 0.6);

        expect(mgr.strTargetPole1, 0.7);
        expect(mgr.strTargetPole2, 0.6);
      });

      test('STR有効時にsetStrTargetPoles：strインスタンスにも反映される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrEnabled(true);
        mgr.setStrTargetPoles(0.8, 0.7);

        expect(mgr.str!.targetPole1, 0.8);
        expect(mgr.str!.targetPole2, 0.7);
      });

      test('STR無効時にsetStrTargetPoles：次の有効化時に反映される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrTargetPoles(0.6, 0.5);

        mgr.setStrEnabled(true);
        expect(mgr.str!.targetPole1, 0.6);
        expect(mgr.str!.targetPole2, 0.5);
      });

      test('setStrTargetPolesButterworth：STR有効時は即座に反映される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrEnabled(true);

        mgr.setStrTargetPolesButterworth(0.5);
        // Butterworth極は帯域幅から計算される（具体的な値は検証しない）
        expect(mgr.strTargetPole1, isNot(0.5)); // デフォルト値から変わることを確認
        expect(mgr.str!.targetPole1, mgr.strTargetPole1);
        expect(mgr.str!.targetPole2, mgr.strTargetPole2);
      });

      test('setStrTargetPolesButterworth：STR無効時も極が保存される', () {
        final mgr = StrManager(useSecondOrderPlant: false);

        mgr.setStrTargetPolesButterworth(0.5);
        final savedPole1 = mgr.strTargetPole1;
        final savedPole2 = mgr.strTargetPole2;

        // 極が変更されていることを確認（デフォルト値とは異なる）
        expect(savedPole1, isNot(0.5));
        expect(savedPole2, isNot(0.3));

        // STR有効化後、保存された極で初期化される
        mgr.setStrEnabled(true);
        expect(mgr.str!.targetPole1, savedPole1);
        expect(mgr.str!.targetPole2, savedPole2);
      });
    });

    group('プラント次数の切替', () {
      test('1次→2次切替：RLSが再生成される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setRlsEnabled(true);
        expect(mgr.rls!.parameterCount, 2);

        mgr.updatePlantOrder(true);
        expect(mgr.useSecondOrderPlant, true);
        expect(mgr.rls!.parameterCount, 4);
      });

      test('2次→1次切替：RLSが再生成される', () {
        final mgr = StrManager(useSecondOrderPlant: true);
        mgr.setRlsEnabled(true);
        expect(mgr.rls!.parameterCount, 4);

        mgr.updatePlantOrder(false);
        expect(mgr.useSecondOrderPlant, false);
        expect(mgr.rls!.parameterCount, 2);
      });

      test('1次→2次切替：STRが再生成される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrEnabled(true);
        expect(mgr.str!.rls.parameterCount, 2);

        mgr.updatePlantOrder(true);
        expect(mgr.str!.rls.parameterCount, 4);
      });

      test('プラント次数切替時：lambda設定は維持される', () {
        final mgr = StrManager(useSecondOrderPlant: false, rlsLambda: 0.95);
        mgr.setRlsEnabled(true);

        mgr.updatePlantOrder(true);
        expect(mgr.rls!.lambda, 0.95);
      });

      test('プラント次数切替時：極設定は維持される', () {
        final mgr = StrManager(
          useSecondOrderPlant: false,
          strTargetPole1: 0.6,
          strTargetPole2: 0.4,
        );
        mgr.setStrEnabled(true);

        mgr.updatePlantOrder(true);
        expect(mgr.str!.targetPole1, 0.6);
        expect(mgr.str!.targetPole2, 0.4);
      });
    });

    group('コントローラのリセット', () {
      test('resetControllers：RLSがリセットされる', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setRlsEnabled(true);

        // RLSを更新して初期状態から変更
        mgr.rls!.update([0.5, 0.3], 0.8);
        final estimatedBeforeReset = mgr.rls!.estimatedA;

        mgr.resetControllers();
        // リセット後は初期化時の値に戻る
        // StrManagerはUIデフォルトのプラント(a=0.8, b=0.5)に合わせた初期値を設定している
        expect(mgr.rls!.estimatedA, 0.8);
        expect(mgr.rls!.estimatedB, 0.5);
        // 更新前とは異なる値になっている
        expect(mgr.rls!.estimatedA, isNot(estimatedBeforeReset));
      });

      test('resetControllers：STRがリセットされる', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrEnabled(true);

        // STRを更新して初期状態から変更
        mgr.str!.rls.update([0.5, 0.3], 0.8);
        final estimatedBeforeReset = mgr.str!.estimatedA;

        mgr.resetControllers();
        // リセット後は初期化時の値に戻る
        // StrManagerはUIデフォルトのプラント(a=0.8, b=0.5)に合わせた初期値を設定している
        expect(mgr.str!.estimatedA, 0.8);
        expect(mgr.str!.estimatedB, 0.5);
        // 更新前とは異なる値になっている
        expect(mgr.str!.estimatedA, isNot(estimatedBeforeReset));
      });

      test('resetControllers：RLS/STR無効時もエラーにならない', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        expect(() => mgr.resetControllers(), returnsNormally);
      });
    });

    group('エッジケース', () {
      test('RLSとSTRの同時有効化', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setRlsEnabled(true);
        mgr.setStrEnabled(true);

        expect(mgr.rlsEnabled, true);
        expect(mgr.strEnabled, true);
        expect(mgr.rls, isNotNull);
        expect(mgr.str, isNotNull);
      });

      test('連続してプラント次数を切り替えても正常動作', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setRlsEnabled(true);

        mgr.updatePlantOrder(true);
        mgr.updatePlantOrder(false);
        mgr.updatePlantOrder(true);

        expect(mgr.rls!.parameterCount, 4);
        expect(mgr.useSecondOrderPlant, true);
      });

      test('極設定→lambda変更→極再設定：正しい順序で反映される', () {
        final mgr = StrManager(useSecondOrderPlant: false);
        mgr.setStrTargetPoles(0.7, 0.6);
        mgr.setRlsLambda(0.95);
        mgr.setStrTargetPoles(0.8, 0.7);

        mgr.setStrEnabled(true);
        expect(mgr.str!.targetPole1, 0.8);
        expect(mgr.str!.targetPole2, 0.7);
        expect(mgr.str!.rls.lambda, 0.95);
      });
    });
  });
}
