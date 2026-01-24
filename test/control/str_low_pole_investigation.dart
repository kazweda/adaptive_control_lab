// p1 < 0.42 での振動挙動調査テスト
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/plant.dart';
import 'package:adaptive_control_lab/control/rls.dart';
import 'package:adaptive_control_lab/control/str.dart';

void main() {
  group('STR 低極値での挙動調査 (p1 < 0.42)', () {
    test('p1=0.40 での安定性を理論値と比較', () {
      const a = 0.8;
      const b = 0.5;
      const p1 = 0.40;
      const r = 1.0;

      final plant = Plant(a: a, b: b);
      // NOTE: RLSパラメータは StrManager のデフォルト値に合わせる
      // lambda: 0.995, initialCovarianceScale: 1.0
      final rls = RLS(
        parameterCount: 2,
        lambda: 0.995,
        initialCovarianceScale: 1.0,
        initialTheta: [a, b],
      );
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p1);

      print('\n=== p1=0.40 での理論値と実測値の比較 ===');
      print('真のプラント: a=$a, b=$b');
      print('目標極: p1=$p1');
      print('予測される閉ループ: y(k) = $p1*y(k-1) + ${1 - p1}*r');
      print('');

      double y = 0.0;
      double prevY = 0.0;
      double prevU = 0.0;
      List<double> yHistory = [y];

      for (int k = 0; k < 50; k++) {
        final u = str.computeControl(y, r);
        y = plant.step(u);
        rls.update([prevY, prevU], y);

        prevY = y;
        prevU = u;
        yHistory.add(y);

        if (k < 15 || k % 5 == 0) {
          final theory = p1 * yHistory[k] + (1 - p1) * r;
          print(
            'k=$k: y=${y.toStringAsFixed(4)}, '
            'u=${u.toStringAsFixed(4)}, '
            'y_theory=${theory.toStringAsFixed(4)}, '
            'a_est=${rls.estimatedA.toStringAsFixed(4)}, '
            'b_est=${rls.estimatedB.toStringAsFixed(4)}',
          );
        }

        if (y.abs() > 100) {
          print('⚠️ 発散: k=$k, y=$y');
          break;
        }
      }

      // 収束性チェック
      final lastY = yHistory.last;
      final convergent = (lastY - r).abs() < 0.1;
      print(
        '\n収束判定: ${convergent ? "収束" : "未収束"} (最終y=${lastY.toStringAsFixed(4)}, '
        'e=${(lastY - r).abs().toStringAsFixed(4)})',
      );

      // 振動の有無をチェック
      int zeroCount = 0;
      for (int i = 1; i < yHistory.length; i++) {
        if ((yHistory[i] - yHistory[i - 1]).sign !=
            (yHistory[i - 1] - (i >= 2 ? yHistory[i - 2] : 0)).sign) {
          zeroCount++;
        }
      }
      print('符号反転回数: $zeroCount 回（振動指標）');
    });

    test('p1=0.30 での挙動', () {
      const a = 0.8;
      const b = 0.5;
      const p1 = 0.30;
      const r = 1.0;

      final plant = Plant(a: a, b: b);
      // NOTE: RLSパラメータは StrManager のデフォルト値に合わせる
      final rls = RLS(
        parameterCount: 2,
        lambda: 0.995,
        initialCovarianceScale: 1.0,
        initialTheta: [a, b],
      );
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p1);

      print('\n=== p1=0.30 での挙動 ===');
      double y = 0.0;
      double prevY = 0.0;
      double prevU = 0.0;

      for (int k = 0; k < 30; k++) {
        final u = str.computeControl(y, r);
        y = plant.step(u);
        rls.update([prevY, prevU], y);

        prevY = y;
        prevU = u;

        if (k < 10) {
          print('k=$k: y=${y.toStringAsFixed(4)}, u=${u.toStringAsFixed(4)}');
        }
      }
      print('最終: y=${y.toStringAsFixed(4)}');
    });

    test('p1=0.20 での挙動（高速応答）', () {
      const a = 0.8;
      const b = 0.5;
      const p1 = 0.20;
      const r = 1.0;

      final plant = Plant(a: a, b: b);
      // NOTE: RLSパラメータは StrManager のデフォルト値に合わせる
      final rls = RLS(
        parameterCount: 2,
        lambda: 0.995,
        initialCovarianceScale: 1.0,
        initialTheta: [a, b],
      );
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p1);

      print('\n=== p1=0.20 での挙動 ===');
      double y = 0.0;
      double prevY = 0.0;
      double prevU = 0.0;

      for (int k = 0; k < 20; k++) {
        final u = str.computeControl(y, r);
        y = plant.step(u);
        rls.update([prevY, prevU], y);

        prevY = y;
        prevU = u;

        if (k < 10) {
          print('k=$k: y=${y.toStringAsFixed(4)}, u=${u.toStringAsFixed(4)}');
        }
      }
      print('最終: y=${y.toStringAsFixed(4)}');
    });

    test('理論解析: 極配置制御則のゲイン', () {
      // 制御則: u = ((1-p)*r - (a-p)*y) / b
      // 正規形では: u = K*r - F*y (ここで K = (1-p)/b, F = (a-p)/b)

      print('\n=== 極配置制御則のゲイン分析 ===');
      const a = 0.8;
      const b = 0.5;

      for (double p1 in [0.20, 0.40, 0.60, 0.80]) {
        final K = (1 - p1) / b;
        final F = (a - p1) / b;
        print(
          'p1=$p1: K=${K.toStringAsFixed(3)} (目標値ゲイン), '
          'F=${F.toStringAsFixed(3)} (フィードバックゲイン)',
        );

        // 安定性判定: F > 0 ならフィードバックが安定に作用
        if (F > 0) {
          print('  → F > 0: フィードバック安定（出力上昇時に抑制）');
        } else {
          print('  → F < 0: フィードバック不安定（出力上昇時に増幅）⚠️');
        }
      }
    });
  });
}
