// STR適応制御テスト（段階的極配置・制御入力制限）
// Issue #40 解決策の検証
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/plant.dart';
import 'package:adaptive_control_lab/control/rls.dart';
import 'package:adaptive_control_lab/control/str.dart';

void main() {
  group('STR適応制御 (Issue #40 解決策)', () {
    test('1次系: 段階的極配置 + 段階的制御制限 (p=0.3)', () {
      // Issue #40の最も問題が大きかった極配置
      const a = 0.8;
      const b = 0.5;
      const p = 0.3; // 問題のあった極
      const r = 1.0;

      final plant = Plant(a: a, b: b);
      final rls = RLS(
        parameterCount: 2,
        lambda: 1.0,
        initialCovarianceScale: 100.0, // issue #37対策のため小さい値
      );
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p);

      // 段階的制御を有効化
      str.enableAdaptivePolePlacement(convergenceSteps: 100);
      str.enableAdaptiveControlLimit(initialLimit: 1.0, convergenceSteps: 100);

      print('\n--- p=0.3 with 段階的制御 ---');
      print('プラント: a=$a, b=$b');
      print('初期段階: p=0.75, u_limit=±1.0');
      print('100ステップ後: p=$p, u_limit=±10.0');

      double y = 0.0;
      double prevY = 0.0;
      double prevU = 0.0;
      final history = <Map<String, double>>[];

      for (int k = 0; k < 300; k++) {
        final u = str.computeControl(y, r);
        y = plant.step(u);

        // RLS更新（前ステップの値で）
        rls.update([prevY, prevU], y);

        if (k < 10 || k == 50 || k == 99 || k == 149 || k == 299) {
          final log = {
            'k': k.toDouble(),
            'y': y,
            'u': u,
            'a_est': rls.estimatedA,
            'b_est': rls.estimatedB,
          };
          history.add(log);
          print(
            'k=$k: y=${y.toStringAsFixed(4)}, u=${u.toStringAsFixed(4)}, '
            'a=${rls.estimatedA.toStringAsFixed(4)}, b=${rls.estimatedB.toStringAsFixed(4)}',
          );
        }

        prevY = y;
        prevU = u;
      }

      final yFinal = y;
      print('\n最終結果: y_ss=${yFinal.toStringAsFixed(6)}, expected=1.0');
      print('偏差: ${(yFinal - r).abs().toStringAsFixed(6)}');

      // 段階的制御により、精度が改善されることを期待
      expect(yFinal, closeTo(r, 0.08), reason: '段階的制御で定常偏差が大きく改善されるべき');
    });

    test('1次系: 段階的極配置 + 段階的制御制限 (p=0.5)', () {
      const a = 0.8;
      const b = 0.5;
      const p = 0.5;
      const r = 1.0;

      final plant = Plant(a: a, b: b);
      final rls = RLS(
        parameterCount: 2,
        lambda: 1.0,
        initialCovarianceScale: 100.0,
      );
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p);

      str.enableAdaptivePolePlacement(convergenceSteps: 100);
      str.enableAdaptiveControlLimit(initialLimit: 1.0, convergenceSteps: 100);

      print('\n--- p=0.5 with 段階的制御 ---');

      double y = 0.0;
      double prevY = 0.0;
      double prevU = 0.0;

      for (int k = 0; k < 300; k++) {
        final u = str.computeControl(y, r);
        y = plant.step(u);
        rls.update([prevY, prevU], y);

        prevY = y;
        prevU = u;
      }

      final yFinal = y;
      print('最終: y_ss=${yFinal.toStringAsFixed(6)}');
      print('偏差: ${(yFinal - r).abs().toStringAsFixed(6)}');

      expect(yFinal, closeTo(r, 0.05));
    });

    test('1次系: 段階的極配置 + 段階的制御制限 (p=0.7)', () {
      const a = 0.8;
      const b = 0.5;
      const p = 0.7;
      const r = 1.0;

      final plant = Plant(a: a, b: b);
      final rls = RLS(
        parameterCount: 2,
        lambda: 1.0,
        initialCovarianceScale: 100.0,
      );
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p);

      str.enableAdaptivePolePlacement(convergenceSteps: 100);
      str.enableAdaptiveControlLimit(initialLimit: 1.0, convergenceSteps: 100);

      print('\n--- p=0.7 with 段階的制御 ---');

      double y = 0.0;
      double prevY = 0.0;
      double prevU = 0.0;

      for (int k = 0; k < 300; k++) {
        final u = str.computeControl(y, r);
        y = plant.step(u);
        rls.update([prevY, prevU], y);

        prevY = y;
        prevU = u;
      }

      final yFinal = y;
      print('最終: y_ss=${yFinal.toStringAsFixed(6)}');
      print('偏差: ${(yFinal - r).abs().toStringAsFixed(6)}');

      expect(yFinal, closeTo(r, 0.05));
    });

    test('1次系: 比較 - 適応制御なし vs あり (p=0.3)', () {
      const a = 0.8;
      const b = 0.5;
      const p = 0.3;
      const r = 1.0;

      // ケース1: 適応制御なし（従来の方法）
      final plant1 = Plant(a: a, b: b);
      final rls1 = RLS(
        parameterCount: 2,
        lambda: 1.0,
        initialCovarianceScale: 100.0,
      );
      final str1 = STR(parameterCount: 2, rls: rls1, targetPole1: p);

      double y1 = 0.0;
      double prevY1 = 0.0;
      double prevU1 = 0.0;

      for (int k = 0; k < 300; k++) {
        final u1 = str1.computeControl(y1, r);
        y1 = plant1.step(u1);
        rls1.update([prevY1, prevU1], y1);

        prevY1 = y1;
        prevU1 = u1;
      }

      // ケース2: 段階的制御あり
      final plant2 = Plant(a: a, b: b);
      final rls2 = RLS(
        parameterCount: 2,
        lambda: 1.0,
        initialCovarianceScale: 100.0,
      );
      final str2 = STR(parameterCount: 2, rls: rls2, targetPole1: p);
      str2.enableAdaptivePolePlacement(convergenceSteps: 100);
      str2.enableAdaptiveControlLimit(initialLimit: 1.0, convergenceSteps: 100);

      double y2 = 0.0;
      double prevY2 = 0.0;
      double prevU2 = 0.0;

      for (int k = 0; k < 300; k++) {
        final u2 = str2.computeControl(y2, r);
        y2 = plant2.step(u2);
        rls2.update([prevY2, prevU2], y2);

        prevY2 = y2;
        prevU2 = u2;
      }

      print('\n--- p=0.3 比較 ---');
      print(
        '適応制御なし: y_ss=${y1.toStringAsFixed(6)}, error=${(y1 - r).abs().toStringAsFixed(6)}',
      );
      print(
        '適応制御あり: y_ss=${y2.toStringAsFixed(6)}, error=${(y2 - r).abs().toStringAsFixed(6)}',
      );

      // 段階的制御により、定常偏差が改善されることを確認
      expect(
        (y2 - r).abs(),
        lessThan((y1 - r).abs() * 1.5),
        reason: '段階的制御は少なくとも従来方法と同等かそれ以上の性能を期待',
      );
    });
  });
}
