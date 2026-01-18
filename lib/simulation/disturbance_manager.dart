import '../control/disturbance.dart';

/// 外乱プリセットの定義
class DisturbancePreset {
  final String name;
  final String displayName;
  final DisturbanceType type;
  final double amplitude;
  final int startStep;
  final double omega;
  final double phase;
  final double noiseStdDev;
  final int noiseSeed;

  DisturbancePreset({
    required this.name,
    required this.displayName,
    required this.type,
    this.amplitude = 0.0,
    this.startStep = 0,
    this.omega = 0.0,
    this.phase = 0.0,
    this.noiseStdDev = 0.0,
    this.noiseSeed = 42,
  });

  /// プリセットから Disturbance を生成
  Disturbance toDisturbance() {
    switch (type) {
      case DisturbanceType.none:
        return Disturbance(type: DisturbanceType.none);
      case DisturbanceType.step:
        return Disturbance(
          type: DisturbanceType.step,
          amplitude: amplitude,
          startStep: startStep,
        );
      case DisturbanceType.impulse:
        return Disturbance(
          type: DisturbanceType.impulse,
          amplitude: amplitude,
          startStep: startStep,
        );
      case DisturbanceType.sinusoid:
        return Disturbance(
          type: DisturbanceType.sinusoid,
          amplitude: amplitude,
          omega: omega,
          phase: phase,
        );
      case DisturbanceType.noise:
        return Disturbance(
          type: DisturbanceType.noise,
          noiseStdDev: noiseStdDev,
          noiseSeed: noiseSeed,
        );
    }
  }
}

/// 外乱管理クラス
///
/// Simulator が扱う外乱状態と外乱プリセット選択の責務をこのクラスに委譲します。
/// 現在有効な [Disturbance] インスタンスと、ユーザーが選択したプリセット名を保持し、
/// UIからの操作に応じて外乱を切り替えるためのユーティリティを提供します。
///
/// ## 役割
/// - 外乱の現在状態（disturbance）を保持
/// - 外乱プリセットの一覧（[getAvailablePresets]）を提供
/// - プリセット名から対応する [DisturbancePreset] を選択し、[Disturbance] を生成
/// - currentPresetName を更新してUIで選択中のプリセットを表示できるようにする
///
/// ## Simulator との関係
/// Simulator は本クラスのインスタンスを1つ保持し、シミュレーションステップごとに
/// disturbance?.next() を通じて外乱値を取得します。
/// 外乱の切り替え（プリセット/カスタム）はすべて DisturbanceManager を経由して行い、
/// Simulator 本体の責務（制御ループや履歴管理）から外乱ロジックを分離しています。
///
/// ## プリセットとカスタム設定の違い
/// - **プリセット適用**: applyPreset('noise_mid') のようにプリセット名で指定すると、
///   あらかじめ定義されたパラメータ（振幅、開始ステップ、周波数、ノイズ分散、乱数シードなど）で
///   Disturbance が再生成されます。再現性のあるシナリオ比較に適しています。
/// - **カスタム設定**: setType(DisturbanceType.sinusoid) のようにタイプのみを変更する場合、
///   currentPresetName は 'Custom' に更新され、「プリセットではない状態」を表します。
///   これによりUIで「プリセット由来の設定」か「手動調整した設定」かを区別できます。
class DisturbanceManager {
  Disturbance? disturbance;
  String currentPresetName = 'なし';

  /// コンストラクタ
  DisturbanceManager() {
    disturbance = Disturbance(type: DisturbanceType.none);
  }

  /// プリセット一覧を取得
  static List<DisturbancePreset> getAvailablePresets() {
    return [
      DisturbancePreset(
        name: 'none',
        displayName: 'なし',
        type: DisturbanceType.none,
      ),
      DisturbancePreset(
        name: 'step_early',
        displayName: 'ステップ外乱（早期）',
        type: DisturbanceType.step,
        amplitude: 0.2,
        startStep: 10,
      ),
      DisturbancePreset(
        name: 'step_mid',
        displayName: 'ステップ外乱（中期）',
        type: DisturbanceType.step,
        amplitude: 0.2,
        startStep: 100,
      ),
      DisturbancePreset(
        name: 'step_large',
        displayName: 'ステップ外乱（大信号）',
        type: DisturbanceType.step,
        amplitude: 0.5,
        startStep: 100,
      ),
      DisturbancePreset(
        name: 'impulse_small',
        displayName: 'インパルス外乱（小）',
        type: DisturbanceType.impulse,
        amplitude: 0.3,
        startStep: 50,
      ),
      DisturbancePreset(
        name: 'impulse_large',
        displayName: 'インパルス外乱（大）',
        type: DisturbanceType.impulse,
        amplitude: 1.0,
        startStep: 100,
      ),
      DisturbancePreset(
        name: 'sinusoid_slow',
        displayName: '正弦波（低周波）',
        type: DisturbanceType.sinusoid,
        amplitude: 0.2,
        omega: 0.05,
        phase: 0.0,
      ),
      DisturbancePreset(
        name: 'sinusoid_mid',
        displayName: '正弦波（中周波）',
        type: DisturbanceType.sinusoid,
        amplitude: 0.2,
        omega: 0.2,
        phase: 0.0,
      ),
      DisturbancePreset(
        name: 'sinusoid_fast',
        displayName: '正弦波（高周波）',
        type: DisturbanceType.sinusoid,
        amplitude: 0.15,
        omega: 0.5,
        phase: 0.0,
      ),
      DisturbancePreset(
        name: 'noise_small',
        displayName: 'ガウス雑音（小）',
        type: DisturbanceType.noise,
        noiseStdDev: 0.03,
        noiseSeed: 42,
      ),
      DisturbancePreset(
        name: 'noise_mid',
        displayName: 'ガウス雑音（中）',
        type: DisturbanceType.noise,
        noiseStdDev: 0.05,
        noiseSeed: 42,
      ),
      DisturbancePreset(
        name: 'noise_large',
        displayName: 'ガウス雑音（大）',
        type: DisturbanceType.noise,
        noiseStdDev: 0.1,
        noiseSeed: 42,
      ),
    ];
  }

  /// プリセットを適用
  void applyPreset(String presetName) {
    final preset = getAvailablePresets().firstWhere(
      (p) => p.name == presetName,
      orElse: () => getAvailablePresets().first,
    );
    disturbance = preset.toDisturbance();
    currentPresetName = preset.displayName;
  }

  /// 外乱タイプを設定（カスタム設定）
  void setType(DisturbanceType type) {
    disturbance = _createDefaultDisturbance(type);
    currentPresetName = 'Custom';
  }

  /// 外乱タイプを取得
  DisturbanceType getType() => disturbance?.type ?? DisturbanceType.none;

  /// 次ステップの外乱値を取得
  double getNext() => disturbance?.next() ?? 0.0;

  /// リセット
  void reset() {
    disturbance?.reset();
    currentPresetName = 'なし';
  }

  /// デフォルト外乱を生成（タイプ別）
  static Disturbance _createDefaultDisturbance(DisturbanceType type) {
    switch (type) {
      case DisturbanceType.none:
        return Disturbance(type: DisturbanceType.none);
      case DisturbanceType.step:
        return Disturbance(
          type: DisturbanceType.step,
          amplitude: 0.2,
          startStep: 50,
        );
      case DisturbanceType.impulse:
        return Disturbance(
          type: DisturbanceType.impulse,
          amplitude: 0.5,
          startStep: 30,
        );
      case DisturbanceType.sinusoid:
        return Disturbance(
          type: DisturbanceType.sinusoid,
          amplitude: 0.2,
          omega: 0.2,
          phase: 0.0,
        );
      case DisturbanceType.noise:
        return Disturbance(
          type: DisturbanceType.noise,
          noiseStdDev: 0.05,
          noiseSeed: 42,
        );
    }
  }
}
