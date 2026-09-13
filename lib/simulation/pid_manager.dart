import '../control/pid.dart';

/// PIDゲインのプリセット定義
///
/// プラント次数（1次/2次）によって発散しにくいゲインの大きさが異なるため、
/// 次数ごとのゲインセットを1つのプリセットにまとめて保持する。
class PIDPreset {
  final String name;
  final String displayName;
  final String description;
  final double kp1; // 1次プラント用 Kp
  final double ki1; // 1次プラント用 Ki
  final double kd1; // 1次プラント用 Kd
  final double kp2; // 2次プラント用 Kp
  final double ki2; // 2次プラント用 Ki
  final double kd2; // 2次プラント用 Kd

  const PIDPreset({
    required this.name,
    required this.displayName,
    required this.description,
    required this.kp1,
    required this.ki1,
    required this.kd1,
    required this.kp2,
    required this.ki2,
    required this.kd2,
  });
}

/// PID制御ロジックを `Simulator` から切り離して管理するクラス
///
/// Simulator からPID制御器の生成・保持・リセットとPIDゲインの参照/更新の責務を委譲されます。
/// これにより、Simulator は制御対象プラントや外乱の管理に集中でき、
/// PID制御の詳細な実装はこのクラスに集約されます。
///
/// ## 主な責務
/// - 現在使用中の [PIDController] インスタンスを保持し、そのライフサイクルを管理
/// - 誤差 e(k) から制御入力 u(k) を計算する [computeControl] を提供
/// - kp, ki, kd のゲインをゲッター/セッターとして公開
/// - シミュレーションのリスタート時に [reset] でPID内部状態をクリア
///
/// ## 静的ファクトリメソッドの使い分け
/// - [createFirstOrderDefault]: 1次プラントモデル向けの標準的なPIDゲイン
/// - [createSecondOrderDefault]: 2次プラント向けに発散を避けるため抑えめのゲイン
///
/// これらは初期値（プリセット）であり、実際のチューニングは
/// シミュレーション結果を見ながらゲインを動的に変更して行います。
class PIDManager {
  late PIDController pidController;

  /// 現在適用中のプリセット名（手動でゲインを変更すると'カスタム'になる）
  String currentPresetName = '標準';

  /// コンストラクタ
  PIDManager(PIDController initialController) {
    pidController = initialController;
  }

  /// 誤差から制御入力を計算
  double computeControl(double error) {
    return pidController.compute(error);
  }

  // === PIDゲイン アクセサ ===
  // 手動でのゲイン変更はプリセットから外れるため 'カスタム' 扱いにする

  double get kp => pidController.kp;
  set kp(double value) {
    pidController.kp = value;
    currentPresetName = 'カスタム';
  }

  double get ki => pidController.ki;
  set ki(double value) {
    pidController.ki = value;
    currentPresetName = 'カスタム';
  }

  double get kd => pidController.kd;
  set kd(double value) {
    pidController.kd = value;
    currentPresetName = 'カスタム';
  }

  /// コントローラーをリセット
  void reset() => pidController.reset();

  /// プリセット一覧を取得
  static List<PIDPreset> getAvailablePresets() {
    return const [
      PIDPreset(
        name: 'gentle',
        displayName: 'おだやか',
        description: 'ゆっくり穏やかに追従',
        kp1: 0.15,
        ki1: 0.03,
        kd1: 0.05,
        kp2: 0.06,
        ki2: 0.01,
        kd2: 0.02,
      ),
      PIDPreset(
        name: 'standard',
        displayName: '標準',
        description: 'バランス重視のデフォルト',
        kp1: 0.3,
        ki1: 0.1,
        kd1: 0.1,
        kp2: 0.12,
        ki2: 0.02,
        kd2: 0.04,
      ),
      PIDPreset(
        name: 'aggressive',
        displayName: 'きびきび',
        description: '速い追従、オーバーシュートに注意',
        kp1: 0.6,
        ki1: 0.2,
        kd1: 0.15,
        kp2: 0.2,
        ki2: 0.04,
        kd2: 0.08,
      ),
    ];
  }

  /// プリセットを適用（プラント次数に応じたゲインセットを使用）
  void applyPreset(String presetName, {required bool isSecondOrder}) {
    final preset = getAvailablePresets().firstWhere(
      (p) => p.name == presetName,
      orElse: () => getAvailablePresets()[1],
    );
    pidController.kp = isSecondOrder ? preset.kp2 : preset.kp1;
    pidController.ki = isSecondOrder ? preset.ki2 : preset.ki1;
    pidController.kd = isSecondOrder ? preset.kd2 : preset.kd1;
    currentPresetName = preset.displayName;
  }

  /// 1次プラント向けの標準PIDゲインを作成
  static PIDController createFirstOrderDefault() {
    return PIDController(kp: 0.3, ki: 0.1, kd: 0.1);
  }

  /// 2次プラント向けの標準PIDゲインを作成
  static PIDController createSecondOrderDefault() {
    // 2次プラントはより抑えめのゲインで初期化（発散防止）
    return PIDController(kp: 0.12, ki: 0.02, kd: 0.04);
  }
}
