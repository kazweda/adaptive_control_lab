# コード品質維持ポリシー

本プロジェクトでは、長期的なメンテナンス性を確保するため、以下の品質基準を維持します。

---

## 1. テストカバレッジ

### 必須テスト対象

すべての制御ロジックには単体テストを作成してください。

| ディレクトリ | カバレッジ目標 | 現状 |
|--------------|----------------|------|
| `lib/control/` | 90%以上 | ✅ 達成 |
| `lib/simulation/` | 90%以上 | ✅ 達成 |
| `lib/ui/` | 50%以上（基本動作） | ⚠️ 部分的 |

### テスト実行

```bash
# カバレッジ付きテスト
flutter test --coverage

# カバレッジレポート生成（オプション）
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 新規コード追加時のルール

1. **制御ロジック**: テストなしでのPRは認めない
2. **UI**: 基本的な動作テストは必須
3. **バグ修正**: 再発防止のテストを追加

---

## 2. コード解析（flutter analyze）

### ゼロ警告ポリシー

**すべてのPRは警告ゼロでマージされなければなりません。**

```bash
# 期待される出力
$ flutter analyze
Analyzing lib...
No issues found! (ran in 0.7s)
```

### 警告レベル

- **Error**: マージ不可（ビルド失敗）
- **Warning**: マージ不可（修正必須）
- **Info**: できる限り修正（deprecated使用など）
- **Hint**: 推奨修正（未使用変数など）

### よくある警告の対処

#### 1. Deprecated API

```dart
// ❌ 非推奨
color: Colors.grey.withOpacity(0.2)

// ✅ 推奨
color: Colors.grey.withValues(alpha: 0.2)
```

#### 2. 未使用の import

```dart
// ❌ 使っていないimport
import 'package:flutter/material.dart';
import 'dart:async'; // 使用していない

// ✅ 必要なもののみ
import 'package:flutter/material.dart';
```

#### 3. 未使用の変数

```dart
// ❌ 使っていない変数
final unused = 10;

// ✅ 削除または使用
// 削除するか、実際に使用する
```

---

## 3. コードフォーマット

### 自動フォーマット必須

PRを作成する前に、必ず `dart format` を実行してください。

```bash
# 全ファイルをフォーマット
dart format .

# 変更の確認のみ（実際には変更しない）
dart format --output=none --set-exit-if-changed .
```

### エディタ設定

VS Codeの場合、保存時に自動フォーマットを有効化：

```json
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "[dart]": {
    "editor.formatOnSave": true
  }
}
```

---

## 4. リファクタリング基準

### ファイルの行数

| 状態 | 行数 | アクション |
|------|------|------------|
| ✅ 良好 | ~300行 | そのまま |
| ⚠️ 注意 | 300~500行 | 分割を検討 |
| ❌ 要対応 | 500行~ | 分割必須 |

```bash
# 行数確認
wc -l lib/**/*.dart | sort -n
```

### 関数の複雑度

| 指標 | 推奨値 | 最大値 |
|------|--------|--------|
| ネストの深さ | 2階層 | 3階層 |
| 関数の行数 | ~30行 | ~50行 |
| Cyclomatic複雑度 | ~5 | ~10 |

#### リファクタリングのタイミング

1. **ネストが3階層を超える**
   → 早期リターンまたは関数分割

2. **関数が50行を超える**
   → 責任ごとに関数分割

3. **同じコードが3回以上出現**
   → 共通関数化

### リファクタリング例

#### Before（ネストが深い）
```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      child: Column(
        children: [
          if (isLoading) {
            CircularProgressIndicator()
          } else {
            if (hasData) {
              DataWidget(data)
            } else {
              ErrorWidget()
            }
          }
        ],
      ),
    ),
  );
}
```

#### After（関数分割）
```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      child: Column(
        children: [_buildContent()],
      ),
    ),
  );
}

Widget _buildContent() {
  if (isLoading) return CircularProgressIndicator();
  if (hasData) return DataWidget(data);
  return ErrorWidget();
}
```

---

## 5. コードレビュー基準

### レビューポイント

#### 機能性
- [ ] 要件を満たしているか
- [ ] エッジケースを考慮しているか
- [ ] エラーハンドリングは適切か

#### コード品質
- [ ] 命名は分かりやすいか
- [ ] コメントは適切か（文系向けの説明があるか）
- [ ] DRY原則（Don't Repeat Yourself）を守っているか

#### テスト
- [ ] テストは十分か
- [ ] テストケース名は分かりやすいか
- [ ] エッジケースもカバーしているか

#### パフォーマンス
- [ ] 不要な再描画はないか
- [ ] リストは効率的に表示されるか
- [ ] メモリリークはないか

---

## 6. 継続的改善

### 定期的なチェック

月に1回、以下を確認して改善します：

1. **テストカバレッジ**
   ```bash
   flutter test --coverage
   ```

2. **コードメトリクス**
   ```bash
   # 行数チェック
   wc -l lib/**/*.dart | sort -rn | head -10
   ```

3. **警告の確認**
   ```bash
   flutter analyze
   ```

### リファクタリングのタイミング

以下のような状況では、積極的にリファクタリングを行います：

1. **3回同じ修正をした場合**
   → 設計を見直す

2. **バグが頻繁に発生する箇所**
   → テストを追加し、コードを整理

3. **新機能追加が困難な箇所**
   → 責任を分離し、拡張しやすくする

---

## 7. ドキュメント

### 必須ドキュメント

- **README.md**: プロジェクト概要、セットアップ手順
- **DEVELOPMENT.md**: 開発手順（このファイル）
- **コード内コメント**: 複雑なロジックには説明を追加

### コメントガイドライン

#### 良いコメント
```dart
/// プラント出力を1ステップ更新
/// 
/// 1次系の差分方程式：y(k) = a*y(k-1) + b*u(k-1)
/// 
/// [input] 現在の制御入力 u(k)
/// 戻り値：更新後のプラント出力 y(k)
double step(double input) {
  _output = a * _output + b * _previousInput;
  _previousInput = input;
  return _output;
}
```

#### 不要なコメント
```dart
// ❌ コードを読めば分かることは書かない
// iを1増やす
i++;

// ❌ TODO without issue reference
// TODO: あとで直す

// ✅ Issue参照付きTODO
// TODO(#123): STR実装時にリファクタリング
```

---

## まとめ

このポリシーに従うことで、以下を実現します：

✅ **バグの早期発見** - テストによる品質保証  
✅ **メンテナンス性向上** - 読みやすく変更しやすいコード  
✅ **チーム開発への準備** - 統一された品質基準  
✅ **技術的負債の削減** - 継続的な改善

---

**質問・提案がある場合は、Issue を作成してください。**

最終更新: 2026年1月12日
