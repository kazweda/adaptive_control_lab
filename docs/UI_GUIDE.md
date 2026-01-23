# UI設計ガイド

このドキュメントでは、アプリのUI設計パターンと各コンポーネントの使い方を説明します。

---

## コントローラー選択とON/OFF機能

### 基本設計

アプリには2つの制御方式タブがあります：

```
┌─────────────────────────────┐
│ ○ PID制御      ○ STR制御    │
└─────────────────────────────┘
```

### STR制御タブのON/OFF機能

**設計意図:**

STR制御タブ内に「STR制御器 ON/OFF」スイッチを配置しています。これは以下の用途のために必要です：

#### 1. **PID vs STR の性能比較**

同じシミュレーション条件下で、2つの制御方式を簡単に切り替えて比較できます。

```
[STR制御タブを選択]
  └─ STR OFF → PID制御のみで動作
  └─ STR ON  → STR制御（自動同定 + 極配置）で動作
```

**使用例:**
1. STR OFFでシミュレーション実行 → PID制御の応答を観察
2. STR ONに切り替えてリセット → STR制御の応答を観察
3. 両者の収束速度・定常偏差・オーバーシュートを比較

#### 2. **RLS単独の動作確認**

STRをOFFにした状態でも、RLSによるパラメータ推定機能は独立して動作可能です。

- **STR OFF + RLS OFF**: 通常のPID制御
- **STR OFF + RLS ON**: パラメータ推定のみ（制御には使用しない）
- **STR ON + RLS ON**: STR制御（推定値を制御に使用）

**使用例（高度）:**
- RLS単独でパラメータ収束を観察
- 推定値の精度やドリフトを確認
- 忘却係数λの調整効果を検証

#### 3. **極配置パラメータの試行錯誤**

STR OFF状態で所望極（targetPole1, targetPole2）を調整し、設定が完了したらSTR ONで適用できます。

**使用例:**
1. STR OFFで極スライダーを操作
2. 目的の応答特性に合わせて極を設定
3. STR ONにして制御開始
4. 結果を見て必要に応じて再調整

---

## UI コンポーネント階層

### メイン画面構成

```
MainScreen
├─ ChartWindowSelector       // グラフ表示範囲選択
├─ TimeSeriesPlot             // 時系列グラフ
├─ SimulationStatusPanel      // ステータス表示
├─ SimulationControlPanel     // 開始/停止/リセット
├─ TargetValuePanel           // 目標値調整
├─ ControllerSelectorPanel    // PID/STRタブ切替
├─ [コントローラー設定画面]   // PIDControllerScreen または STRControllerScreen
│   ├─ PIDControllerScreen
│   │   ├─ PIDゲイン調整スライダー (Kp, Ki, Kd)
│   │   └─ 推奨ゲインボタン
│   │
│   └─ STRControllerScreen
│       ├─ STR制御器 ON/OFF スイッチ ← **重要**
│       ├─ 所望の極スライダー (targetPole1, targetPole2)
│       ├─ Butterworth配置ボタン（2次系のみ）
│       └─ 推定パラメータ表示
│
├─ PlantParamsPanel           // プラントパラメータ調整
└─ DisturbancePanel           // 外乱設定
```

---

## 設計判断の記録

### なぜタブ選択とは別にON/OFFスイッチが必要か？

**代替案A: タブ選択 = 自動有効化**
```
STR制御タブを開く → 常にSTR ON
```

❌ **問題点:**
- PIDとSTRの比較が困難（タブ切替のたびにリセットが必要）
- RLS単独の動作確認ができない
- パラメータ調整中も制御が動作してしまう

**採用案: タブ選択 + 明示的なON/OFF**
```
STR制御タブを開く → STR OFF/ONを選択可能
```

✅ **利点:**
- 柔軟な比較テストが可能
- RLS単独モードをサポート
- パラメータ調整の自由度が高い
- UIが明示的で混乱が少ない

---

## 実装ファイル

### STRControllerScreen

**ファイル:** `lib/ui/controllers/str_controller_screen.dart`

**主要ウィジェット:**
- `_buildSTREnableSection()`: STR ON/OFFスイッチ
- `_buildTargetPolesSection()`: 極配置パラメータ調整
- `_buildEstimatedParametersSection()`: RLS推定値表示

**状態管理:**
```dart
// Simulatorクラスで管理
simulator.strEnabled      // STR制御の有効/無効
simulator.rlsEnabled      // RLS推定の有効/無効
simulator.setStrEnabled(bool)
```

---

## 関連Issue

- #46: STR制御タブのON/OFF機能の説明ドキュメント作成

---

**最終更新**: 2026年1月23日
