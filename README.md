# adaptive_control_lab

Flutter を用いた **制御系シミュレーション・可視化アプリ**。

本プロジェクトでは、  
**PID 制御** と **Self-Tuning Regulator（STR）** を同一プラント上で比較し、
制御性能・適応性の違いを視覚的に理解することを目的とする。

---

## 🌐 Web Demo

> **[Demo サイト](https://kazweda.github.io/adaptive_control_lab/)** で今すぐお試しください！  
> ブラウザのみで動作。インストール不要です。

---

## 📚 ドキュメント

- **[開発手順ガイド](docs/DEVELOPMENT.md)** - 開発フロー、PR作成手順
- **[コード品質ポリシー](docs/QUALITY_POLICY.md)** - テスト、リファクタリング基準

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

## 評価シナリオ（初学者向け）

直感的に「うまくいく／いかない」を体験できる代表パターンを用意する場合のリスト。

**評価軸**
- 立ち上がり・整定時間 / オーバーシュート / 定常偏差
- 振動・発散の有無
- 外乱後の収束時間

**1次プラント例** `y(k)=a·y(k-1)+b·u(k-1)`
- 成功: a=0.6, b=0.7 / Kp=0.6, Ki=0.15, Kd=0.05 → 速く整定、オーバーシュート小
- 安全・遅め: a=0.8, b=0.5 / Kp=0.25, Ki=0.05, Kd=0.0 → オーバーシュートほぼ0、遅いが安定
- オーバーシュート例: a=0.8, b=0.5 / Kp=1.0, Ki=0.2, Kd=0.0 → 行き過ぎ後に数回振動
- 発散寄り: a=0.9, b=0.4 / Kp=1.2, Ki=0.3, Kd=0.0 → 振幅が増大、ゲイン過大の危険例
- 定常偏差が残る: a=0.7, b=0.4 / Kp=0.5, Ki=0.0, Kd=0.05 → 早く落ち着くが目標に届かない（Kiの役割）
- ノイズに弱い: a=0.6, b=0.6 / Kp=0.5, Ki=0.1, Kd=0.5 → 入力がギザギザ（Kd過大）

**2次プラント例** `y(k)=a1·y(k-1)+a2·y(k-2)+b1·u(k-1)+b2·u(k-2)`
- 成功: a1=1.1, a2=-0.3, b1=0.5, b2=0.1 / Kp=0.4, Ki=0.08, Kd=0.08 → 軽い振動で整定
- 失敗（減衰不足）: a1=1.2, a2=-0.32, b1=0.45, b2=0.08 / Kp=0.8, Ki=0.15, Kd=0.0 → 振動が長引く

**外乱応答プリセット活用**
- ステップ外乱（早期/大）: step_early / step_large
- インパルス: impulse_small / impulse_large
- サイン波: sinusoid_mid（ω=0.2, amp=0.2）
- 雑音: noise_mid（std=0.05, seed=42）
→ 「外乱後の整定時間」「オーバーシュート」を比較指標として記録すると分かりやすい。

**簡易チェックリスト**
- Kp大: オーバーシュート・振動
- Kiなし: 定常偏差が残る
- Ki大: 遅い振動／発散
- Kd大: ノイズ増幅でギザギザ
- 2次プラントで減衰不足: 長引く振動

---

## 🧪 テスト

```bash
# 全テスト実行
flutter test

# カバレッジ付きテスト
flutter test --coverage

# コード解析
flutter analyze
```

### テストカバレッジ

- `lib/control/`: ✅ 90%以上
- `lib/simulation/`: ✅ 90%以上
- `lib/ui/`: ⚠️ 部分的

---

## Roadmap

- [x] 1次系 + PID
- [x] 2次系 + 外乱
- [x] Flutter Web 対応
- [ ] RLS 同定
- [ ] STR 実装
- [ ] アニメーション課題（エレベータ、車両速度制御など）

---

## Goal

制御理論の理解を深めるための  
**実験可能・直感的・拡張可能** なシミュレーション環境を構築する。
