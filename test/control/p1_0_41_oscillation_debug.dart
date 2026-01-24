// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/simulation/simulator.dart';

void main() {
  group('p1=0.41 振動問題 デバッグ', () {
    test('p1=0.41: step 10から振動が開始される詳細分析', () {
      final sim = Simulator();
      sim.setStrEnabled(true);
      sim.setStrTargetPoles(0.41, 0.41);
      sim.targetValue = 1.0;

      print('\n=== p1=0.41 振動デバッグ開始 ===');
      print('プラント: a=${sim.plantParamA}, b=${sim.plantParamB}');
      print('RLS暖機期間: step 0-9 (RLS更新なし)');
      print('RLS更新開始: step 10以降');
      print('');

      for (int k = 0; k < 30; k++) {
        final yBefore = sim.plantOutput;
        final aEstBefore = sim.estimatedA;
        final bEstBefore = sim.estimatedB;

        sim.step();

        final yAfter = sim.plantOutput;
        final uCurrent = sim.controlInput;
        final aEstAfter = sim.estimatedA;
        final bEstAfter = sim.estimatedB;

        // Step 10-15 と step 25-30 を詳細表示
        if (k >= 8 && k <= 15 || k >= 24 && k <= 29) {
          print(
            'k=$k: '
            'y_before=${yBefore.toStringAsFixed(4)} → y_after=${yAfter.toStringAsFixed(4)}, '
            'u=${uCurrent.toStringAsFixed(4)}, '
            'a_est=${aEstAfter.toStringAsFixed(4)} (Δ${(aEstAfter - aEstBefore).toStringAsFixed(6)}), '
            'b_est=${bEstAfter.toStringAsFixed(4)} (Δ${(bEstAfter - bEstBefore).toStringAsFixed(6)})',
          );
        }
      }

      final controlHistoryLength = sim.historyControl.length;
      if (controlHistoryLength >= 20) {
        print('\n--- 制御入力の最後20ステップ ---');
        for (int i = controlHistoryLength - 20; i < controlHistoryLength; i++) {
          print('u[$i]=${sim.historyControl[i].toStringAsFixed(4)}');
        }
      }

      print('\n--- 最終状態 ---');
      print('y_final=${sim.plantOutput.toStringAsFixed(6)}');
      print(
        'a_est=${sim.estimatedA.toStringAsFixed(6)}, true_a=${sim.plantParamA}',
      );
      print(
        'b_est=${sim.estimatedB.toStringAsFixed(6)}, true_b=${sim.plantParamB}',
      );
      print('isHalted=${sim.isHalted}');

      // 振動が発生しているかチェック
      if (controlHistoryLength >= 20) {
        final u20to29 = sim.historyControl.sublist(
          controlHistoryLength - 20,
          controlHistoryLength,
        );
        final hasLargeSwings = u20to29.any((u) => u.abs() > 8.0);
        final alternatesSign = u20to29.asMap().entries.skip(1).any((entry) {
          return u20to29[entry.key - 1] * entry.value < 0;
        });

        print('\n--- 振動検出 ---');
        print('|u| > 8.0 の存在: $hasLargeSwings');
        print('符号反転の存在: $alternatesSign');
      }
    });

    test('p1=0.41: RLS更新禁止の影響確認 (step 10で更新禁止を維持)', () {
      // このテストは比較用：RLS更新禁止期間を延長した場合の動作を確認
      final sim = Simulator();
      sim.setStrEnabled(true);
      sim.setStrTargetPoles(0.41, 0.41);
      sim.targetValue = 1.0;

      print('\n=== RLS更新禁止期間延長テスト (step 0-20) ===');

      for (int k = 0; k < 50; k++) {
        final aEstBefore = sim.estimatedA;

        sim.step();

        final aEstAfter = sim.estimatedA;
        final changed = (aEstAfter - aEstBefore).abs() > 1e-6;

        if (k >= 8 && k <= 25) {
          print(
            'k=$k: y=${sim.plantOutput.toStringAsFixed(4)}, '
            'u=${sim.controlInput.toStringAsFixed(4)}, '
            'a_est=${aEstAfter.toStringAsFixed(4)} '
            '(changed=$changed)',
          );
        }
      }

      print(
        '最終: y=${sim.plantOutput.toStringAsFixed(6)}, '
        'a_est=${sim.estimatedA.toStringAsFixed(6)}',
      );
    });

    test('p1=0.40: リセット前後での RLS 状態を確認', () {
      final sim = Simulator();

      // === 1回目の実行 ===
      print('\n=== 1回目の実行 (p1=0.40) ===');
      sim.setStrEnabled(true);
      sim.setStrTargetPoles(0.40, 0.40);
      sim.targetValue = 1.0;

      print('初期状態: a_est=${sim.estimatedA}, b_est=${sim.estimatedB}');

      // step 0-15 を実行
      for (int k = 0; k < 16; k++) {
        sim.step();

        if (k <= 12 || k == 15) {
          print(
            'k=$k: y=${sim.plantOutput.toStringAsFixed(4)}, '
            'u=${sim.controlInput.toStringAsFixed(4)}, '
            'a_est=${sim.estimatedA.toStringAsFixed(4)}, '
            'b_est=${sim.estimatedB.toStringAsFixed(4)}',
          );
        }
      }

      final y1After15 = sim.plantOutput;
      final a1After15 = sim.estimatedA;
      final b1After15 = sim.estimatedB;
      print(
        '\n1回目 最終状態(k=15): y=$y1After15, a_est=$a1After15, b_est=$b1After15',
      );

      // === リセット ===
      print('\n=== リセット実行 ===');
      sim.reset();
      print(
        'リセット直後: a_est=${sim.estimatedA}, b_est=${sim.estimatedB}, y=${sim.plantOutput}',
      );

      // === 2回目の実行 ===
      print('\n=== 2回目の実行 (リセット後、同じ p1=0.40) ===');
      sim.setStrEnabled(true);
      sim.setStrTargetPoles(0.40, 0.40);
      sim.targetValue = 1.0;

      print('初期設定後: a_est=${sim.estimatedA}, b_est=${sim.estimatedB}');

      // step 0-15 を実行
      for (int k = 0; k < 16; k++) {
        sim.step();

        if (k <= 12 || k == 15) {
          print(
            'k=$k: y=${sim.plantOutput.toStringAsFixed(4)}, '
            'u=${sim.controlInput.toStringAsFixed(4)}, '
            'a_est=${sim.estimatedA.toStringAsFixed(4)}, '
            'b_est=${sim.estimatedB.toStringAsFixed(4)}',
          );
        }
      }

      final y2After15 = sim.plantOutput;
      final a2After15 = sim.estimatedA;
      final b2After15 = sim.estimatedB;
      print(
        '\n2回目 最終状態(k=15): y=$y2After15, a_est=$a2After15, b_est=$b2After15',
      );

      // === 比較 ===
      print('\n=== 実行結果の比較 ===');
      print('y の差異: ${(y1After15 - y2After15).abs().toStringAsFixed(6)}');
      print('a_est の差異: ${(a1After15 - a2After15).abs().toStringAsFixed(6)}');
      print('b_est の差異: ${(b1After15 - b2After15).abs().toStringAsFixed(6)}');

      // 同じ結果が得られることを確認
      expect(
        (y1After15 - y2After15).abs(),
        lessThan(0.001),
        reason: '1回目と2回目の出力値が一致すべき',
      );
      expect(
        (a1After15 - a2After15).abs(),
        lessThan(0.001),
        reason: '1回目と2回目の a_est が一致すべき',
      );
      expect(
        (b1After15 - b2After15).abs(),
        lessThan(0.001),
        reason: '1回目と2回目の b_est が一致すべき',
      );
    });

    test('p1=0.40: 連続実行 3 回実行で振動パターンを確認', () {
      final sim = Simulator();

      for (int run = 1; run <= 3; run++) {
        print('\n=== 実行 $run ===');
        sim.setStrEnabled(true);
        sim.setStrTargetPoles(0.40, 0.40);
        sim.targetValue = 1.0;

        print('初期: a_est=${sim.estimatedA}, b_est=${sim.estimatedB}');

        // step 0-20 を実行
        final uValues = <double>[];
        for (int k = 0; k < 21; k++) {
          sim.step();
          uValues.add(sim.controlInput);

          if (k >= 8 && k <= 15) {
            print(
              'k=$k: y=${sim.plantOutput.toStringAsFixed(4)}, '
              'u=${sim.controlInput.toStringAsFixed(4)}, '
              'a_est=${sim.estimatedA.toStringAsFixed(4)}, '
              'b_est=${sim.estimatedB.toStringAsFixed(4)}',
            );
          }
        }

        // 最後の10ステップで振動があるかチェック
        final u10to20 = uValues.sublist(10);
        final maxSwing = u10to20
            .reduce((a, b) => a.abs() > b.abs() ? a : b)
            .abs();
        print('最後10ステップの最大制御入力: ${maxSwing.toStringAsFixed(4)}');

        // リセット
        if (run < 3) {
          print('リセット前: 履歴数=${sim.historyOutput.length}');
          sim.reset();
          print('リセット後: 履歴数=${sim.historyOutput.length}');
        }
      }
    });
  });
}
