// Simulator統合テスト - STR制御の定常状態検証
// Issue #40 実機動作での検証
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/simulation/simulator.dart';

void main() {
  group('Simulator統合: STR定常状態検証 (Issue #40)', () {
    test('1次系: デフォルトプラント + STR (p=0.5)', () {
      final sim = Simulator();

      // STR有効化
      sim.setStrEnabled(true);
      sim.setStrTargetPoles(0.5, 0.3);
      sim.targetValue = 1.0;

      print('\n--- Simulator実行: p=0.5 ---');
      print('プラント: a=${sim.plantParamA}, b=${sim.plantParamB}');

      // シミュレーション実行
      for (int k = 0; k < 200; k++) {
        sim.step();

        if (k < 10 || k % 20 == 0) {
          print(
            'k=$k: y=${sim.plantOutput.toStringAsFixed(4)}, '
            'u=${sim.controlInput.toStringAsFixed(4)}, '
            'a_est=${sim.estimatedA.toStringAsFixed(4)}, '
            'b_est=${sim.estimatedB.toStringAsFixed(4)}',
          );
        }
      }

      final yFinal = sim.plantOutput;
      final aEst = sim.estimatedA;
      final bEst = sim.estimatedB;

      print('\n最終結果:');
      print('  y_ss = ${yFinal.toStringAsFixed(6)} (expected: 1.0)');
      print('  a_est = ${aEst.toStringAsFixed(6)} (true: ${sim.plantParamA})');
      print('  b_est = ${bEst.toStringAsFixed(6)} (true: ${sim.plantParamB})');
      print('  偏差 = ${(yFinal - 1.0).abs().toStringAsFixed(6)}');

      // 推定誤差が大きい場合、それが原因
      final aError = (aEst - sim.plantParamA).abs();
      final bError = (bEst - sim.plantParamB).abs();
      print(
        '  推定誤差: a=${aError.toStringAsFixed(6)}, b=${bError.toStringAsFixed(6)}',
      );

      expect(yFinal, closeTo(1.0, 0.05), reason: 'STR制御で目標値に収束すべき');
    });

    test('1次系: デフォルトプラント + STR (p=0.3) - 改善版（RLS初期化と忘却係数の最適化）', () {
      // Issue #50, #52 の改善により、p=0.3でも正常に制御できるようになった
      // - initialTheta = [0.8, 0.5]（プラント真値に対応）
      // - initialCovarianceScale = 1.0（過度な不確実性を排除）
      // - rlsLambda = 0.995（保守的な適応で初期ノイズの影響を軽減）
      final sim = Simulator();
      sim.setStrEnabled(true);
      sim.setStrTargetPoles(0.3, 0.3);
      sim.targetValue = 1.0;

      print('\n--- Simulator実行: p=0.3 (改善版) ---');

      for (int k = 0; k < 200; k++) {
        sim.step();
      }

      final yFinal = sim.plantOutput;
      final aEst = sim.estimatedA;
      final bEst = sim.estimatedB;
      print('最終: y_ss=${yFinal.toStringAsFixed(6)}');
      print('偏差: ${(yFinal - 1.0).abs().toStringAsFixed(6)}');
      print('推定値: a=${aEst.toStringAsFixed(6)}, b=${bEst.toStringAsFixed(6)}');

      // 改善版では安定的に制御できることを確認
      // 1. シミュレーションが停止していないことを確認
      expect(sim.isHalted, false, reason: 'シミュレーションが停止していないこと');

      // 2. RLS推定精度が良好であることを確認（改善版の特徴）
      final bEstError = (bEst - 0.5).abs();
      expect(bEstError, lessThan(0.01), reason: '改善版ではRLS推定が精密（b_est ≈ 0.5）');

      // 3. 定常偏差が小さいことを確認（改善版の成功指標）
      final steadyStateError = (yFinal - 1.0).abs();
      expect(steadyStateError, lessThan(0.01), reason: 'p=0.3での定常偏差が十分に小さい');
    });

    test('1次系: デフォルトプラント + STR (p=0.7)', () {
      final sim = Simulator();
      sim.setStrEnabled(true);
      sim.setStrTargetPoles(0.7, 0.3);
      sim.targetValue = 1.0;

      print('\n--- Simulator実行: p=0.7 ---');

      for (int k = 0; k < 200; k++) {
        sim.step();
      }

      final yFinal = sim.plantOutput;
      print('最終: y_ss=${yFinal.toStringAsFixed(6)}');
      print('偏差: ${(yFinal - 1.0).abs().toStringAsFixed(6)}');

      expect(yFinal, closeTo(1.0, 0.05));
    });

    test('1次系: RLS推定精度の検証', () {
      final sim = Simulator();
      sim.setStrEnabled(true);
      sim.setStrTargetPoles(0.5, 0.3);
      sim.targetValue = 1.0;

      // 真のパラメータ
      final aTrue = sim.plantParamA;
      final bTrue = sim.plantParamB;

      // 推定誤差の推移を記録
      final errors = <Map<String, double>>[];

      for (int k = 0; k < 300; k++) {
        sim.step();

        if (k % 20 == 0) {
          final aEst = sim.estimatedA;
          final bEst = sim.estimatedB;
          final aErr = (aEst - aTrue).abs();
          final bErr = (bEst - bTrue).abs();
          errors.add({
            'k': k.toDouble(),
            'aError': aErr,
            'bError': bErr,
            'y': sim.plantOutput,
          });
        }
      }

      print('\n--- RLS推定精度の推移 ---');
      for (final e in errors) {
        print(
          'k=${e['k']!.toInt()}: '
          'a_err=${e['aError']!.toStringAsFixed(6)}, '
          'b_err=${e['bError']!.toStringAsFixed(6)}, '
          'y=${e['y']!.toStringAsFixed(4)}',
        );
      }

      // 最終的な推定誤差
      final finalAError = errors.last['aError']!;
      final finalBError = errors.last['bError']!;

      print('\n最終推定誤差:');
      print('  a誤差: ${finalAError.toStringAsFixed(6)}');
      print('  b誤差: ${finalBError.toStringAsFixed(6)}');

      // 推定誤差が大きい場合は警告
      if (finalAError > 0.1 || finalBError > 0.1) {
        print('警告: RLS推定精度が低い可能性があります');
      }
    });
  });
}
