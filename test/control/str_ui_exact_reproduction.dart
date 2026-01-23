// UIの正確な再現テスト
// RLS初期値: [0.5, 0.3] (UIのデフォルト)
// 極配置パラメータ: p1=0.81
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/control/plant.dart';
import 'package:adaptive_control_lab/control/rls.dart';
import 'package:adaptive_control_lab/control/str.dart';

void main() {
  group('STR UI再現テスト (p1=0.81, RLS初期=[0.5, 0.3])', () {
    test('UI条件での p1=0.81 動作確認', () {
      const a = 0.8; // 真のプラントパラメータ
      const b = 0.5;
      const p1 = 0.81; // 目標極
      const r = 1.0; // 目標値

      // UIと同じ条件: RLS初期推定値はデフォルト [0.5, 0.3]
      final plant = Plant(a: a, b: b);
      final rls = RLS(
        parameterCount: 2,
        lambda: 1.0,
        initialCovarianceScale: 100.0,
        // initialTheta を指定しない → デフォルト [0.5, 0.3] を使用
      );
      final str = STR(parameterCount: 2, rls: rls, targetPole1: p1);

      print('\n=== UI条件での p1=0.81 再現テスト ===');
      print('真のプラント: a=$a, b=$b');
      print('RLS初期推定値: ${rls.theta}');
      print('目標極: p=$p1');
      print('制御入力制限: ±${str.controlInputLimit}');
      print('');

      double y = 0.0;
      double prevY = 0.0;
      double prevU = 0.0;

      for (int k = 0; k < 10; k++) {
        final u = str.computeControl(y, r);

        if (k < 6) {
          print(
            'step:$k y=${y.toStringAsFixed(3)}, u=${u.toStringAsFixed(3)}, '
            'a_est=${rls.estimatedA.toStringAsFixed(4)}, '
            'b_est=${rls.estimatedB.toStringAsFixed(4)}',
          );
        }

        y = plant.step(u);
        rls.update([prevY, prevU], y);

        prevY = y;
        prevU = u;

        // 発散検出
        if (y.abs() > 100) {
          print('⚠️  発散検出: step=$k, y=$y');
          break;
        }
      }

      print('\n結果: RLS初期値[0.5, 0.3]での制御入力飽和が再現できましたか？');
    });

    test('比較: RLS初期値が異なる場合の影響', () {
      const a = 0.8;
      const b = 0.5;
      const p1 = 0.81;
      const r = 1.0;

      print('\n=== RLS初期値の影響比較 ===');

      // ケース1: UIのデフォルト値 [0.5, 0.3]
      {
        final plant1 = Plant(a: a, b: b);
        final rls1 = RLS(
          parameterCount: 2,
          lambda: 1.0,
          initialCovarianceScale: 100.0,
        );
        final str1 = STR(parameterCount: 2, rls: rls1, targetPole1: p1);

        print('\nケース1: RLS初期=[0.5, 0.3]（UIデフォルト）');
        double y = 0.0;
        for (int k = 0; k < 5; k++) {
          final u = str1.computeControl(y, r);
          print('  step:$k u=${u.toStringAsFixed(3)}');
          y = plant1.step(u);
        }
      }

      // ケース2: 診断テストの値 [0.8, 0.5]
      {
        final plant2 = Plant(a: a, b: b);
        final rls2 = RLS(
          parameterCount: 2,
          lambda: 1.0,
          initialCovarianceScale: 100.0,
          initialTheta: [a, b], // 正確な推定値で初期化
        );
        final str2 = STR(parameterCount: 2, rls: rls2, targetPole1: p1);

        print('\nケース2: RLS初期=[0.8, 0.5]（診断テスト）');
        double y = 0.0;
        for (int k = 0; k < 5; k++) {
          final u = str2.computeControl(y, r);
          print('  step:$k u=${u.toStringAsFixed(3)}');
          y = plant2.step(u);
        }
      }

      print('\n分析: RLS初期値の違いが制御入力に大きな影響を与えています');
    });

    test('極配置制御則の手動計算検証', () {
      // 極配置制御則: u(k) = ((1-p)*r - (a-p)*y) / b
      // p1=0.81, a=0.8 → (a-p) = -0.01

      const p1 = 0.81;
      const a = 0.8;
      const b = 0.5;
      const r = 1.0;

      print('\n=== 極配置制御則の手動計算 ===');
      print('制御則: u(k) = ((1-p)*r - (a-p)*y) / b');
      print('  p=$p1, a=$a, b=$b, r=$r');
      print('');

      // y値の異なるケースでの制御入力を計算
      for (double y in [0.0, 0.317, 5.0, 8.0]) {
        final uTheory = ((1 - p1) * r - (a - p1) * y) / b;
        final clamped = uTheory.clamp(-10.0, 10.0);
        print(
          'y=${y.toStringAsFixed(3)}: u_theory=${uTheory.toStringAsFixed(3)}, '
          'clamped=${clamped.toStringAsFixed(3)}',
        );
      }

      print('');
      print('分析: (a-p) = -0.01 が負なので、yが大きいほどuも負に大きくなる');
      print('これが制御入力飽和の原因です');
    });
  });
}
