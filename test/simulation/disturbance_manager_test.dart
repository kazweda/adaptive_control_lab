import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_control_lab/simulation/disturbance_manager.dart';
import 'package:adaptive_control_lab/control/disturbance.dart';

void main() {
  group('DisturbanceManager', () {
    late DisturbanceManager manager;

    setUp(() {
      manager = DisturbanceManager();
    });

    test('初期状態は外乱なし', () {
      expect(manager.getType(), DisturbanceType.none);
      expect(manager.currentPresetName, 'なし');
      expect(manager.getNext(), 0.0);
    });

    test('getAvailablePresets は12個のプリセットを返す', () {
      final presets = DisturbanceManager.getAvailablePresets();
      expect(presets.length, 12);
    });

    test('全プリセット名が想定通り', () {
      final presets = DisturbanceManager.getAvailablePresets();
      final names = presets.map((p) => p.name).toList();

      expect(names, contains('none'));
      expect(names, contains('step_early'));
      expect(names, contains('step_mid'));
      expect(names, contains('step_large'));
      expect(names, contains('impulse_small'));
      expect(names, contains('impulse_large'));
      expect(names, contains('sinusoid_slow'));
      expect(names, contains('sinusoid_mid'));
      expect(names, contains('sinusoid_fast'));
      expect(names, contains('noise_small'));
      expect(names, contains('noise_mid'));
      expect(names, contains('noise_large'));
    });

    test('applyPreset で none を適用', () {
      manager.applyPreset('none');
      expect(manager.getType(), DisturbanceType.none);
      expect(manager.currentPresetName, 'なし');
      expect(manager.getNext(), 0.0);
    });

    test('applyPreset で step_mid を適用', () {
      manager.applyPreset('step_mid');
      expect(manager.getType(), DisturbanceType.step);
      expect(manager.currentPresetName, 'ステップ外乱（中期）');
    });

    test('applyPreset で noise_mid を適用', () {
      manager.applyPreset('noise_mid');
      expect(manager.getType(), DisturbanceType.noise);
      expect(manager.currentPresetName, 'ガウス雑音（中）');

      // ノイズはランダム値を返す（0以外）
      final noise = manager.getNext();
      expect(noise, isA<double>());
    });

    test('setType でカスタム外乱タイプを設定', () {
      manager.setType(DisturbanceType.sinusoid);
      expect(manager.getType(), DisturbanceType.sinusoid);
      expect(manager.currentPresetName, 'Custom');
    });

    test('setType 後に getNext で値を取得できる', () {
      manager.setType(DisturbanceType.step);

      // ステップ外乱は startStep 前は0
      for (int i = 0; i < 50; i++) {
        manager.getNext();
      }

      // startStep 後は amplitude の値
      final value = manager.getNext();
      expect(value, isA<double>());
    });

    test('reset で外乱状態がリセットされる', () {
      manager.applyPreset('step_mid');

      // 複数回呼び出してステップカウンタを進める
      for (int i = 0; i < 100; i++) {
        manager.getNext();
      }

      manager.reset();
      expect(manager.currentPresetName, 'なし');
    });

    test('存在しないプリセット名を指定すると none にフォールバック', () {
      manager.applyPreset('invalid_preset');
      expect(manager.getType(), DisturbanceType.none);
    });

    test('プリセット適用後にタイプ変更するとカスタムになる', () {
      manager.applyPreset('step_mid');
      expect(manager.currentPresetName, 'ステップ外乱（中期）');

      manager.setType(DisturbanceType.impulse);
      expect(manager.currentPresetName, 'Custom');
      expect(manager.getType(), DisturbanceType.impulse);
    });

    test('異なるプリセットを連続で適用できる', () {
      manager.applyPreset('noise_small');
      expect(manager.currentPresetName, 'ガウス雑音（小）');

      manager.applyPreset('sinusoid_fast');
      expect(manager.currentPresetName, '正弦波（高周波）');
      expect(manager.getType(), DisturbanceType.sinusoid);
    });

    test('DisturbancePreset の toDisturbance が正しく動作', () {
      final presets = DisturbanceManager.getAvailablePresets();

      for (final preset in presets) {
        final disturbance = preset.toDisturbance();
        expect(disturbance.type, preset.type);
      }
    });

    test('step 外乱プリセットのパラメータ確認', () {
      final presets = DisturbanceManager.getAvailablePresets();
      final stepEarly = presets.firstWhere((p) => p.name == 'step_early');

      expect(stepEarly.type, DisturbanceType.step);
      expect(stepEarly.amplitude, 0.2);
      expect(stepEarly.startStep, 10);
    });

    test('noise 外乱プリセットは固定シードで再現性あり', () {
      final presets = DisturbanceManager.getAvailablePresets();
      final noiseMid = presets.firstWhere((p) => p.name == 'noise_mid');

      expect(noiseMid.type, DisturbanceType.noise);
      expect(noiseMid.noiseSeed, 42); // 再現性のための固定シード
    });

    test('sinusoid 外乱プリセットのパラメータ確認', () {
      final presets = DisturbanceManager.getAvailablePresets();
      final sinusoidSlow = presets.firstWhere((p) => p.name == 'sinusoid_slow');

      expect(sinusoidSlow.type, DisturbanceType.sinusoid);
      expect(sinusoidSlow.omega, 0.05);
    });
  });

  group('DisturbancePreset', () {
    test('toDisturbance は各タイプで正しい Disturbance を生成', () {
      final nonePreset = DisturbancePreset(
        name: 'test_none',
        displayName: 'Test None',
        type: DisturbanceType.none,
      );

      final disturbance = nonePreset.toDisturbance();
      expect(disturbance.type, DisturbanceType.none);
    });
  });
}
