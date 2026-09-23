# UI設計ガイド

このドキュメントでは、アプリのUI設計パターンと各コンポーネントの使い方を説明します。

---

## コントローラー選択（PID / STR 排他切替）

### 基本設計

アプリには2つの制御方式があり、操作パネルのセグメントボタンでどちらか一方を選択します：

```
┌─────────────────────────────┐
│ ○ PID制御      ○ STR制御    │
└─────────────────────────────┘
```

セグメントボタンの選択がそのまま `simulator.setStrEnabled(bool)` を呼び出し、制御方式を切り替えます（`main_screen.dart` の `onControllerChanged`）。制御ロジック側は `strEnabled` が true なら STR の制御則（極配置）のみ、false なら PID のみを使う完全な排他選択で、両者を同時に併用するモードはありません（`simulator.dart` の `step()`）。

**PID vs STR の性能比較:**

同じシミュレーション条件下で、セグメントボタンを切り替えてリセット→再実行することで比較できます。

1. PID制御を選択してシミュレーション実行 → PID制御の応答を観察
2. STR制御に切り替えてリセット → STR制御の応答を観察
3. 両者の収束速度・定常偏差・オーバーシュートを比較

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
│       ├─ 所望の極スライダー (targetPole1, targetPole2)
│       ├─ Butterworth配置ボタン（2次系のみ）
│       └─ 推定パラメータ表示
│
├─ PlantParamsPanel           // プラントパラメータ調整
└─ DisturbancePanel           // 外乱設定
```

---

## 設計判断の記録

### なぜタブ選択＝有効化にしたか？

以前はタブ選択とは別にSTR制御タブ内に独立したON/OFFスイッチがあり、「STRタブを開いていてもPIDのみで動作させる」中間状態を選べました。しかし操作対象が2箇所（タブ＋スイッチ）に分かれて分かりにくいという指摘（Issue #73）を受け、タブ選択＝即座にその制御方式が有効になる仕様に整理しました（PR #76）。

```
PID/STRセグメントボタンで選択 → 選択した方式が即座に有効
```

- 操作箇所が1つになりUIがシンプルになった
- PID vs STRの比較は、セグメントボタンを切り替えてリセット→再実行することで引き続き可能
- RLS単独モード（`rlsEnabled`、推定のみ行いPID制御を継続）は現在UIから操作できない内部フラグとして残っているのみで、通常の利用フローには含まれない

---

## 実装ファイル

### STRControllerScreen

**ファイル:** `lib/ui/controllers/str_controller_screen.dart`

**主要ウィジェット:**
- `_buildTargetPolesSection()`: 極配置パラメータ調整
- `_buildEstimatedParametersSection()`: RLS推定値表示

**状態管理:**
```dart
// Simulatorクラスで管理
simulator.strEnabled      // STR制御の有効/無効（PID/STRの排他切替）
simulator.setStrEnabled(bool)
```

呼び出し元は `lib/ui/main_screen.dart` の操作パネル（`SimulationControlPanel`）のセグメントボタンのみです。

---

## 関連Issue

- #46: STR制御タブのON/OFF機能の説明ドキュメント作成（本ドキュメントの初版）
- #65, #68: 操作パネル・カード配置のUI整理
- #73: STR画面内の独立ON/OFFスイッチを廃止し、操作パネルのセグメントボタンに統合（PR #76）

---

**最終更新**: 2026年9月23日
