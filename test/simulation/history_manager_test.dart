import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/simulation/history_manager.dart';

void main() {
  group('HistoryManager', () {
    late HistoryManager history;

    setUp(() {
      history = HistoryManager(maxLength: 10);
    });

    test('初期状態では全履歴が空', () {
      expect(history.length, 0);
      expect(history.target, isEmpty);
      expect(history.output, isEmpty);
      expect(history.control, isEmpty);
      expect(history.estimatedA, isEmpty);
      expect(history.estimatedB, isEmpty);
      expect(history.estimatedA1, isEmpty);
      expect(history.estimatedA2, isEmpty);
      expect(history.estimatedB1, isEmpty);
      expect(history.estimatedB2, isEmpty);
    });

    test('addStep で基本履歴が追加される', () {
      history.addStep(targetValue: 1.0, outputValue: 0.5, controlValue: 0.3);

      expect(history.length, 1);
      expect(history.target, [1.0]);
      expect(history.output, [0.5]);
      expect(history.control, [0.3]);
    });

    test('addFirstOrderEstimates で1次推定値が追加される', () {
      history.addFirstOrderEstimates(a: 0.8, b: 0.5);

      expect(history.estimatedA, [0.8]);
      expect(history.estimatedB, [0.5]);
      expect(history.estimatedA1, isEmpty); // 2次は空のまま
    });

    test('addSecondOrderEstimates で2次推定値が追加される', () {
      history.addSecondOrderEstimates(a1: 0.9, a2: -0.2, b1: 0.4, b2: 0.1);

      expect(history.estimatedA1, [0.9]);
      expect(history.estimatedA2, [-0.2]);
      expect(history.estimatedB1, [0.4]);
      expect(history.estimatedB2, [0.1]);
      expect(history.estimatedA, isEmpty); // 1次は空のまま
    });

    test('maxLength を超えると自動トリミング（基本履歴）', () {
      // maxLength=10 なので 11個追加すると最古の1個が削除される
      for (int i = 0; i < 11; i++) {
        history.addStep(
          targetValue: i.toDouble(),
          outputValue: i.toDouble() + 0.1,
          controlValue: i.toDouble() + 0.2,
        );
      }

      expect(history.length, 10);
      expect(history.target.first, 1.0); // 0.0 が削除されて 1.0 が先頭
      expect(history.target.last, 10.0);
    });

    test('maxLength を超えると自動トリミング（1次推定値）', () {
      for (int i = 0; i < 11; i++) {
        history.addFirstOrderEstimates(a: i.toDouble(), b: i.toDouble() + 0.5);
      }

      expect(history.estimatedA.length, 10);
      expect(history.estimatedA.first, 1.0); // 0.0 が削除
      expect(history.estimatedB.first, 1.5);
    });

    test('maxLength を超えると自動トリミング（2次推定値）', () {
      for (int i = 0; i < 11; i++) {
        history.addSecondOrderEstimates(
          a1: i.toDouble(),
          a2: i.toDouble() + 0.1,
          b1: i.toDouble() + 0.2,
          b2: i.toDouble() + 0.3,
        );
      }

      expect(history.estimatedA1.length, 10);
      expect(history.estimatedA1.first, 1.0); // 0.0 が削除
      expect(history.estimatedA2.first, 1.1);
      expect(history.estimatedB1.first, 1.2);
      expect(history.estimatedB2.first, 1.3);
    });

    test('clearAll で全履歴がクリアされる', () {
      history.addStep(targetValue: 1.0, outputValue: 0.5, controlValue: 0.3);
      history.addFirstOrderEstimates(a: 0.8, b: 0.5);
      history.addSecondOrderEstimates(a1: 0.9, a2: -0.2, b1: 0.4, b2: 0.1);

      history.clearAll();

      expect(history.length, 0);
      expect(history.target, isEmpty);
      expect(history.output, isEmpty);
      expect(history.control, isEmpty);
      expect(history.estimatedA, isEmpty);
      expect(history.estimatedB, isEmpty);
      expect(history.estimatedA1, isEmpty);
      expect(history.estimatedA2, isEmpty);
      expect(history.estimatedB1, isEmpty);
      expect(history.estimatedB2, isEmpty);
    });

    test('clearRlsEstimates でRLS推定値のみクリアされる', () {
      history.addStep(targetValue: 1.0, outputValue: 0.5, controlValue: 0.3);
      history.addFirstOrderEstimates(a: 0.8, b: 0.5);
      history.addSecondOrderEstimates(a1: 0.9, a2: -0.2, b1: 0.4, b2: 0.1);

      history.clearRlsEstimates();

      // 基本履歴は残る
      expect(history.length, 1);
      expect(history.target, [1.0]);
      expect(history.output, [0.5]);
      expect(history.control, [0.3]);

      // RLS推定値はクリアされる
      expect(history.estimatedA, isEmpty);
      expect(history.estimatedB, isEmpty);
      expect(history.estimatedA1, isEmpty);
      expect(history.estimatedA2, isEmpty);
      expect(history.estimatedB1, isEmpty);
      expect(history.estimatedB2, isEmpty);
    });

    test('toString はデバッグ情報を含む', () {
      history.addStep(targetValue: 1.0, outputValue: 0.5, controlValue: 0.3);
      history.addFirstOrderEstimates(a: 0.8, b: 0.5);

      final str = history.toString();
      expect(str, contains('length: 1/10'));
      expect(str, contains('hasRlsFirstOrder: true'));
      expect(str, contains('hasRlsSecondOrder: false'));
    });

    test('基本履歴とRLS推定値の長さは独立して管理される', () {
      // 基本履歴を3ステップ追加
      for (int i = 0; i < 3; i++) {
        history.addStep(
          targetValue: i.toDouble(),
          outputValue: i.toDouble(),
          controlValue: i.toDouble(),
        );
      }

      // RLS推定値を5ステップ追加（基本履歴とは非同期）
      for (int i = 0; i < 5; i++) {
        history.addFirstOrderEstimates(a: i.toDouble(), b: i.toDouble());
      }

      expect(history.length, 3);
      expect(history.estimatedA.length, 5);
      expect(history.estimatedB.length, 5);
    });
  });
}
