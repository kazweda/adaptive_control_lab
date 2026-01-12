# adaptive_control_lab

Flutter を用いた **制御系シミュレーション・可視化アプリ**。

本プロジェクトでは、  
**PID 制御** と **Self-Tuning Regulator（STR）** を同一プラント上で比較し、
制御性能・適応性の違いを視覚的に理解することを目的とする。

---

## Features

- 離散時間プラントシミュレーション（1次 / 2次系）
- PID 制御（固定ゲイン）
- Self-Tuning Regulator（RLS によるオンライン同定）
- 目標値追従・外乱応答のリアルタイム可視化
- プラントパラメータの動的変更

---

## Control Models

### Plant Model (Discrete Time)

```math
y(k) = a_1 y(k-1) + a_2 y(k-2) + b_1 u(k-1)
```

- パラメータは実行中に変更可能
- モデル不一致・外乱の再現を目的とする

---

### PID Controller

```math
u(k) = K_p e(k) + K_i \sum e(k) + K_d (e(k) - e(k-1))
```

- ゲインは UI から手動調整
- プラント変動に対しては非適応

---

### Self-Tuning Regulator (STR)

#### Identification Model (ARX)

```math
y(k) = \hat a_1 y(k-1) + \hat a_2 y(k-2) + \hat b_1 u(k-1)
```

#### Parameter Estimation

- Recursive Least Squares (RLS)
- Forgetting factor 対応予定

#### Control Law

- 極配置ベース
- 同定結果から制御入力を逐次更新

---

## Project Structure

```
lib/
 ├ control/
 │   ├ plant.dart        // プラントモデル
 │   ├ pid.dart          // PID制御器
 │   ├ str.dart          // STR制御器
 │   └ rls.dart          // RLS同定ロジック
 │
 ├ simulation/
 │   └ simulator.dart   // 時間更新・状態管理
 │
 ├ ui/
 │   ├ plot.dart         // 時系列グラフ
 │   ├ control_panel.dart
 │   └ main_screen.dart
 │
 └ main.dart
```

---

## Simulation Loop

- Fixed interval discrete-time simulation
- `Timer.periodic` または `Ticker` を使用

```dart
Timer.periodic(const Duration(milliseconds: 50), (_) {
  simulator.step();
});
```

リアルタイム精度よりも **挙動の分かりやすさ** を優先する。

---

## Visualization

- Reference vs Output
- Control input
- Estimated parameters (STR)

STR の適応過程が視覚的に確認できることを重視する。

---

## Roadmap

- [ ] 1次系 + PID
- [ ] 2次系 + 外乱
- [ ] RLS 同定
- [ ] STR 実装
- [ ] Flutter Web 対応

---

## Goal

制御理論の理解を深めるための  
**実験可能・直感的・拡張可能** なシミュレーション環境を構築する。
