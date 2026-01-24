## 実装内容

RLS（再帰最小二乗法）の初期値をreset時に保持する機能を実装し、p1=0.40/0.41での振動問題（Issue #52 の関連現象）を解決しました。

**注**: このPRは Issue #52「STRからPIDの切り替えエラー」をすべて解決するものではなく、その過程で発見された関連する振動問題に対応しています。STR→PID切り替え機能の修正は別途対応予定です。

## 問題（振動問題）

- **症状**: p1=0.40で安定・収束するが、リセットして再実行するとstep 11から制御入力が-10...+10で振動開始
- **根本原因**: `RLS.reset()` がコンストラクタで設定された初期値 `initialTheta=[0.8, 0.5]` を無視して、ハードコードされたデフォルト値 `[0.5, 0.3]` に戻していた
- **発生メカニズム**:
  1. StrManager初期化時に `initialTheta=[0.8, 0.5]` を設定（UIデフォルトプラント真値）
  2. Simulator.reset()でRLSがリセットされ、初期値がデフォルトに戻る
  3. step 10でRLS暖機期間終了 → RLS更新開始
  4. 初期値の誤差により推定値が著しく変動 → 制御ゲイン急増 → 振動発生

## 解決策

### 1. RLS クラスの改善 (`lib/control/rls.dart`)
- **新フィールド**: `late final List<double> _initialTheta` を追加
  - コンストラクタ時の初期値を保持
  - 独立したコピーを保持（`_theta` が更新されても影響なし）
- **reset() メソッド改善**: 
  - 従来: `_theta = _createDefaultInitialTheta()` → ハードコード値に上書き
  - 改善: `_theta = List.from(_initialTheta)` → 保持された初期値を復元

### 2. RLS更新のウォームアップ期間設定 (`lib/simulation/simulator.dart`)
- step 0-9 で RLS更新をスキップしてinitialTheta への信頼度を保持
- step 10 以降で RLS更新を開始
  - ウォームアップ期間を設けることで、初期推定値のノイズ影響を軽減
  - 低極値（p1<0.42）での安定性向上

### 3. RLS デフォルトパラメータの調整 (`lib/simulation/str_manager.dart`)
- **rlsLambda**: 0.98 → **0.995** （より保守的な適応）
  - 忘却係数を増加させることで、古いデータへの重みを保持
  - 初期推定値が正確な場合に有効（true: a=0.8, b=0.5 ）
  - 低極値での推定値安定性向上
- **initialCovarianceScale**: 100.0 → **1.0** （初期信頼度向上）
  - 初期パラメータ推定値への信頼度を大幅に増加
  - initialTheta=[0.8, 0.5]がプラント真値に近い場合に有効
  - ウォームアップ期間と組み合わせて、過度な適応を抑制

**パラメータ選定の理由:**
- ウォームアップ期間（10ステップ）により初期データのノイズ影響を排除
- initialTheta がプラント真値に合致しているため、保守的な適応が有効
- 低極値（p1<0.42）での制御ゲイン急増を抑制

### 4. テスト期待値の更新
以下の3箇所で、reset後の期待値をデフォルト値 `[0.5, 0.3]` から保持値 `[0.8, 0.5]` に更新：
- `test/simulation/simulator_rls_test.dart` (1箇所)
- `test/simulation/str_manager_test.dart` (2箇所)

### 5. デバッグテストスイートの追加 (`test/control/p1_0_41_oscillation_debug.dart`)
振動問題の詳細分析用テスト4個を追加：
- `p1=0.41: step 10から振動が開始される詳細分析` - RLS更新開始時の状態変化を詳細ログ出力
- `p1=0.41: RLS更新禁止の影響確認` - ウォームアップ期間延長時の動作確認
- `p1=0.40: リセット前後での RLS 状態を確認` - リセット前後の一貫性検証
- `p1=0.40: 連続実行 3 回実行で振動パターンを確認` - 連続実行での安定性確認

## 変更ファイル

| ファイル | 内容 |
|---------|------|
| `lib/control/rls.dart` | _initialTheta フィールド追加、reset() 改善 |
| `lib/simulation/simulator.dart` | rlsWarmupSteps パラメータ追加（デフォルト 10）、reset() のコメント明確化 |
| `lib/simulation/str_manager.dart` | rlsLambda=0.995, initialCovarianceScale=1.0 に変更 |
| `test/simulation/simulator_rls_test.dart` | reset期待値更新 (1) |
| `test/simulation/str_manager_test.dart` | reset期待値更新 (2) |
| `test/control/p1_0_41_oscillation_debug.dart` | デバッグテストスイート新規作成 |
| `test/control/str_low_pole_investigation.dart` | デバッグテスト、RLS パラメータをStrManager デフォルトに統一 |

## テスト結果

✅ **全テスト合格**: 228/228 テスト成功  
✅ **Lint警告**: 0件 (avoid_print warnings 39個を ignore_for_file で対応)  
✅ **静的解析**: flutter analyze "No issues found!"

## 検証内容

- ✅ p1=0.40でリセット前後の出力一致（誤差 < 0.001）
- ✅ RLS初期値 `[0.8, 0.5]` が reset後も保持される
- ✅ step 10でのRLS更新が正常に機能
- ✅ 制御入力が安定値付近（~0.4）に収束

## 関連Issue

Addresses #52 (関連現象の解決 / STR→PID切り替え機能の修正は別途対応予定)

## チェックリスト

- [x] テスト実行 (228/228 合格)
- [x] コード品質チェック (flutter analyze OK)
- [x] コード整形完了 (dart format)
- [x] QUALITY_POLICY.md準拠 (control層 90%+ テストカバレッジ)
- [x] デバッグテスト作成 (振動問題検証用)
