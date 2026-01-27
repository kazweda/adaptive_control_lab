# 開発手順ガイド

このドキュメントでは、`adaptive_control_lab` プロジェクトの開発手順と品質維持のガイドラインを記載します。

---

## 目次

1. [開発フロー](#開発フロー)
2. [コード品質維持](#コード品質維持)
3. [テストガイドライン](#テストガイドライン)
4. [リファクタリング基準](#リファクタリング基準)
5. [PR作成手順](#pr作成手順)

---

## 開発フロー

### 1. Issue の作成

新機能や修正を開始する前に、GitHub Issue を作成します。

```bash
gh issue create --title "[フェーズX] 機能名" --body "## 目標\n...\n\n## 要件\n..."
```

### 2. フィーチャーブランチの作成

`main` ブランチから新しいブランチを作成します。

```bash
git checkout main
git pull origin main
git checkout -b feature/機能名
```

**ブランチ命名規則:**
- 新機能: `feature/機能名`
- バグ修正: `fix/修正内容`
- リファクタリング: `refactor/対象`
- ドキュメント: `docs/内容`

### 3. 開発・テスト

コードを実装しながら、随時テストを実行します。

```bash
# コード解析
flutter analyze

# フォーマット
dart format .

# テスト実行
flutter test

# 特定のテストのみ実行
flutter test test/control/plant_test.dart
```

### 4. コミット

小さく、意味のある単位でコミットします。

```bash
git add .
git commit -m "feat: 実装内容

- 詳細1
- 詳細2

Implements: #issue番号"
```

**日本語を含むコミットメッセージ作成時の注意:**

ターミナルの `-m` フラグに日本語を直接渡すと文字化けする可能性があります。

**推奨方法: ファイルから読み込む**
```bash
# コミットメッセージファイルを作成
cat > /tmp/commit_msg.txt << 'EOF'
feat: 機能名

- 詳細1
- 詳細2

Implements: #issue番号
EOF

# ファイルから読み込んでコミット
git add .
git commit -F /tmp/commit_msg.txt
```

**コミットメッセージ規則:**
- `feat:` 新機能
- `fix:` バグ修正
- `refactor:` リファクタリング
- `test:` テスト追加・修正
- `docs:` ドキュメント更新
- `style:` コードフォーマット
- `chore:` ビルド・設定変更

### 5. PR 作成

```bash
git push -u origin feature/機能名
gh pr create --title "feat: 機能名" --body "Implements #issue番号"
```

**重要: 日本語を含むPR本文の作成時は、以下の問題に注意してください。**

#### 文字化け問題の回避方法

`--body` フラグに日本語を直接渡すと文字化けします。特にバックスラッシュ（\）やバッククォート（`）を含む場合は必ず失敗します。

**推奨方法 1: 英語のみで作成（最も確実）**
```bash
gh pr create --title "fix: issue title" --body "Fix details. Fixes #XX"
```

**推奨方法 2: 本文ファイルを使用（日本語対応）**
```bash
# UTF-8ファイルを作成してから
cat > /tmp/pr_body.txt << 'EOF'
## 実装内容
...
EOF

# ファイルから読み込み
gh pr create --title "feat: 機能名" --body-file /tmp/pr_body.txt
```

**推奨方法 3: GitHub UI から直接作成**
- `git push` 後、ブラウザで GitHub を開く
- "Compare & pull request" ボタンから作成
- 日本語フォーム入力で文字化けなし

### 6. コードレビュー（Copilot）

GitHub Copilot が自動的にコードレビューを実行します。指摘事項があれば修正します。

#### Copilot レビューコメントの確認

```bash
# PR番号を指定してレビューコメントを取得（JSON形式）
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments

# 実際の使用例
gh api repos/kazweda/adaptive_control_lab/pulls/6/comments

# レビュー全体を取得
gh api repos/kazweda/adaptive_control_lab/pulls/6/reviews

# jqで整形して読みやすく表示
gh api repos/kazweda/adaptive_control_lab/pulls/6/comments | jq '.[] | {path: .path, line: .line, body: .body}'
```

### 7. マージ

```bash
gh pr merge PR番号 --squash --delete-branch
```

**重要: マージ後は必ずローカルを同期してください**

```bash
# マージ後、ローカルのmainを最新化
git checkout main
git pull origin main
```

GitHub Actionsがマージ後に自動でビルド番号を+1するため、次の開発前に必ず`pull`してください。

---

## ビルド番号管理

### 手動更新の運用

このプロジェクトでは、PRを作成する前にfeatureブランチでビルド番号を手動で+1します。

#### 更新タイミング

**PR作成前**に、featureブランチ内で以下を実行してください:

```bash
# pubspec.yamlのビルド番号を手動で+1
# 例: version: 1.0.1+3 → version: 1.0.1+4
```

エディタで `pubspec.yaml` の `version:` 行を編集し、`+` の後の数字をインクリメントします。

#### 開発時の注意点

#### ✅ やるべきこと
- **PR作成前**に必ずビルド番号を+1
- 最新のmainブランチから開発開始
- マージ後は `git pull origin main` でローカルを最新化

#### ❌ やってはいけないこと
- ビルド番号の更新を忘れたままPR作成
- 古いmainブランチから新ブランチを作成

### 運用フロー

```bash
# 1. 最新のmainから開始
git checkout main
git pull origin main

# 2. featureブランチで開発
git checkout -b feature/new-feature
# ... 実装 & テスト ...

# 3. PR作成前にビルド番号を更新（重要！）
# pubspec.yaml を編集: version: 1.0.1+3 → version: 1.0.1+4

git add pubspec.yaml
git commit -m "chore: bump build number to +4"
git push origin feature/new-feature

# 4. PR作成
gh pr create --title "feat: New feature" --body-file pr.md

# 5. レビュー & マージ
gh pr merge XX --squash --delete-branch

# 6. ローカルを同期
git checkout main
git pull origin main

# 7. 次の開発へ
git checkout -b feature/next-feature
```

### バージョン番号（MAJOR.MINOR.PATCH）の更新

セマンティックバージョン（MAJOR.MINOR.PATCH）は、リリース時に更新します。

```bash
# リリース時にバージョンを更新
./scripts/bump_version.sh [major|minor|patch]

# 例: 1.0.1 → 1.0.2 (ビルド番号は1にリセット)
./scripts/bump_version.sh patch

# 詳細は docs/VERSION_MANAGEMENT.md を参照
```

---

## コード品質維持

### 警告の解消

**必須**: すべての警告を解消してから PR を作成してください。

```bash
# 警告チェック
flutter analyze

# 期待される出力
# "No issues found!"
```

### コードフォーマット

Flutter の標準フォーマッタを使用します。

```bash
# 全ファイルをフォーマット
dart format .

# 特定のファイルをフォーマット
dart format lib/control/plant.dart
```

---

## テストガイドライン

### テストカバレッジ目標

- **単体テスト**: すべての制御ロジック（Plant, PID, Simulator）
- **ウィジェットテスト**: 基本的なUI動作
- **統合テスト**: 将来的に追加予定

### テスト実行コマンド

```bash
# 全テスト実行
flutter test

# カバレッジ付き実行
flutter test --coverage

# 特定のテストのみ実行
flutter test test/control/
```

### テスト作成ガイドライン

1. **各機能に対応するテストファイルを作成**
   - `lib/control/plant.dart` → `test/control/plant_test.dart`

2. **テストケースの構成**
   ```dart
   group('クラス名', () {
     test('初期状態の確認', () { ... });
     test('基本動作の確認', () { ... });
     test('エッジケースの確認', () { ... });
   });
   ```

3. **テスト内容**
   - 初期状態の確認
   - 正常系の動作確認
   - 異常系・エッジケースの確認
   - リセット機能の確認

### 新機能追加時の手順

1. テストファイルを先に作成（TDD推奨）
2. テストが失敗することを確認
3. 実装を追加
4. テストがパスすることを確認

---

## リファクタリング基準

コードの可読性と保守性を維持するため、以下の基準を設けます。

### ファイルの行数制限

- **推奨**: 1ファイル 300行以内
- **最大**: 1ファイル 500行以内

500行を超える場合は、ファイル分割を検討してください。

```bash
# 行数確認
wc -l lib/**/*.dart
```

### 関数の複雑度

- **ネストの深さ**: 最大 3階層
- **関数の長さ**: 推奨 50行以内

#### リファクタリング例

**悪い例（ネストが深い）:**
```dart
void process() {
  if (condition1) {
    if (condition2) {
      if (condition3) {
        // 処理
      }
    }
  }
}
```

**良い例（早期リターン）:**
```dart
void process() {
  if (!condition1) return;
  if (!condition2) return;
  if (!condition3) return;
  // 処理
}
```

### クラス設計

- **単一責任の原則**: 1クラス1責任
- **依存性の注入**: コンストラクタで依存を渡す
- **イミュータブル**: 可能な限り `final` を使用

---

## PR作成手順

### チェックリスト

PR を作成する前に、以下を確認してください。

- [ ] `flutter analyze` でエラー・警告なし
- [ ] `flutter test` で全テストパス
- [ ] 新機能にはテストを追加
- [ ] コードはフォーマット済み (`dart format`)
- [ ] コミットメッセージは規約に従っている
- [ ] Issue番号を記載（`Implements #XX` または `Closes #XX`）

### PR テンプレート

```markdown
## 実装内容

### 機能/修正の説明
- ...

## 動作確認
- [ ] flutter analyze - エラーなし
- [ ] flutter test - 全テストパス
- [ ] 実機/シミュレータで動作確認

## 関連Issue
Implements #XX
```

---

## トラブルシューティング

### テストが失敗する

```bash
# 詳細なエラーログを表示
flutter test --reporter expanded

# 特定のテストのみ実行
flutter test test/control/plant_test.dart
```

### ビルドが失敗する

```bash
# 依存関係を再取得
flutter clean
flutter pub get

# キャッシュをクリア
flutter pub cache repair
```

### コード解析の警告が多い

```bash
# 警告の詳細を確認
flutter analyze --verbose

# 特定のファイルのみ解析
flutter analyze lib/control/plant.dart
```

---

## 参考資料

- [Flutter コーディング規約](https://dart.dev/guides/language/effective-dart)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [STR制御チューニングガイド](./STR_TUNING_GUIDE.md) - ソフトスタート機能と2次プラント制御
- [バージョン管理ガイド](./VERSION_MANAGEMENT.md) - セマンティックバージョニングとビルド番号

---

**最終更新**: 2026年1月27日
