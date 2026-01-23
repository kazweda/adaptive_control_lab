/// STR制御の定常状態分析テスト
/// Issue #40 の根本原因調査用

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/plant.dart';
import 'package:adaptive_control_lab/control/second_order_plant.dart';
import 'package:adaptive_control_lab/control/rls.dart';
import 'package:adaptive_control_lab/control/str.dart';

void main() {
  group('STR定常状態分析 (Issue #40 調査)', () {
    test('1次系: 理論的DCゲイン検証 (p=0.3)', () {
      // 真のプラントパラメータ
      const a = 0.8;
      const b = 0.5;
      const p = 0.3; // 目標極
      const r = 1.0; // 目標値

      // 理論的な閉ループ伝達関数
      // 定常状態: y_ss = r_ss
      // u(k) = ((1-p)*r - (a-p)*y) / b
      // 定常状態で u_ss = ((1-p) - (a-p))*r / b = (1-a)*r / b
      // プラント: y_ss = a*y_ss + b*u_ss
      // y_ss = b*u_ss / (1-a) = b*(1-a)*r / (b*(1-a)) = r ✓

      final plant = Plant(a: a, b: b);
      final rls = RLS(
        parameterCount: 2,
        lambda: 1.0,
        initialTheta: [a, b], // 完全な推定値
      );
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p);

      // 定常状態まで実行
      for (int k = 0; k < 100; k++) {
        final u = str.computeControl(plant.output, r);
        plant.step(u);
      }

      print('p=$p, y_ss=${plant.output}, expected=1.0');
      expect(plant.output, closeTo(r, 1e-3));
    });

    test('1次系: 理論的DCゲイン検証 (p=0.5)', () {
      const a = 0.8;
      const b = 0.5;
      const p = 0.5;
      const r = 1.0;

      final plant = Plant(a: a, b: b);
      final rls = RLS(parameterCount: 2, lambda: 1.0, initialTheta: [a, b]);
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p);

      for (int k = 0; k < 100; k++) {
        final u = str.computeControl(plant.output, r);
        plant.step(u);
      }

      print('p=$p, y_ss=${plant.output}, expected=1.0');
      expect(plant.output, closeTo(r, 1e-3));
    });

    test('1次系: 理論的DCゲイン検証 (p=0.7)', () {
      const a = 0.8;
      const b = 0.5;
      const p = 0.7;
      const r = 1.0;

      final plant = Plant(a: a, b: b);
      final rls = RLS(parameterCount: 2, lambda: 1.0, initialTheta: [a, b]);
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p);

      for (int k = 0; k < 100; k++) {
        final u = str.computeControl(plant.output, r);
        plant.step(u);
      }

      print('p=$p, y_ss=${plant.output}, expected=1.0');
      expect(plant.output, closeTo(r, 1e-3));
    });

    test('1次系: 制御則の手動計算検証 (p=0.5)', () {
      // 手動で閉ループシステムの定常状態を計算
      const a = 0.8;
      const b = 0.5;
      const p = 0.5;
      const r = 1.0;

      // 定常状態: u_ss = ((1-p)*r - (a-p)*y_ss) / b
      // プラント: y_ss = a*y_ss + b*u_ss
      // y_ss(1-a) = b*u_ss
      // y_ss(1-a) = b * ((1-p)*r - (a-p)*y_ss) / b
      // y_ss(1-a) = (1-p)*r - (a-p)*y_ss
      // y_ss(1-a) + (a-p)*y_ss = (1-p)*r
      // y_ss((1-a) + (a-p)) = (1-p)*r
      // y_ss(1-p) = (1-p)*r
      // y_ss = r ✓ (if p != 1)

      // 実際にシミュレーション
      final plant = Plant(a: a, b: b);
      final rls = RLS(parameterCount: 2, lambda: 1.0, initialTheta: [a, b]);
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p);

      double y = 0.0;
      double u = 0.0;

      // ステップ応答をトレース
      print('\n--- p=0.5 のステップ応答 ---');
      for (int k = 0; k < 30; k++) {
        u = str.computeControl(y, r);
        y = plant.step(u);
        if (k < 10 || k % 5 == 0) {
          print('k=$k: y=${y.toStringAsFixed(4)}, u=${u.toStringAsFixed(4)}');
        }
      }

      print('最終: y_ss=${y.toStringAsFixed(6)}, expected=1.0');
      print('偏差: ${(y - r).abs().toStringAsFixed(6)}');
    });

    test('2次系: 理論的DCゲイン検証 (p1=0.5, p2=0.3)', () {
      // 2次プラント
      const a1 = 1.6;
      const a2 = -0.64;
      const b1 = 0.5;
      const b2 = 0.2;
      const p1 = 0.5;
      const p2 = 0.3;
      const r = 1.0;

      // 定常状態の理論値
      // y_ss = a1*y_ss + a2*y_ss + b1*u_ss + b2*u_ss
      // y_ss(1 - a1 - a2) = (b1 + b2)*u_ss
      // u_ss = (1 - p1 - p2 - p1*p2)*r - (a1 - p1 - p2)*y_ss - (a2 - p1*p2)*y_ss - b2*u_ss
      //      = (1 - p1 - p2 - p1*p2)*r - (a1 + a2 - p1 - p2 - p1*p2)*y_ss - b2*u_ss
      // u_ss(1 + b2) = (1 - p1 - p2 - p1*p2)*r - (a1 + a2 - p1 - p2 - p1*p2)*y_ss
      // ... 複雑な代数

      final plant = SecondOrderPlant(a1: a1, a2: a2, b1: b1, b2: b2);
      final rls = RLS(
        parameterCount: 4,
        lambda: 1.0,
        initialTheta: [a1, a2, b1, b2],
      );
      final str = STR(
        parameterCount: 4,
        rls: rls,
        targetPole1: p1,
        targetPole2: p2,
      );

      for (int k = 0; k < 300; k++) {
        final u = str.computeControl(plant.output, r);
        plant.step(u);
      }

      print('2次系: y_ss=${plant.output}, expected=1.0');
      expect(plant.output, closeTo(r, 1e-2));
    });
  });
}
