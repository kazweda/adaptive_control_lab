# アプリケーションバージョン管理ガイド

## 概要

このプロジェクトでは、セマンティックバージョニング（Semantic Versioning）に基づくバージョン管理を実装しています。ユーザー向けには UI 画面右上にアプリケーション版数を動的に表示し、デプロイ時には自動更新スクリプトでバージョンを一元管理します。

## バージョンスキーム

```
MAJOR.MINOR.PATCH+BUILD_NUMBER

例: 1.0.0+1
```

- **MAJOR**: 互換性を損なう変更
- **MINOR**: 後方互換的な機能追加
- **PATCH**: バグ修正
- **BUILD_NUMBER**: ビルド番号（PR作成前に手動で+1）

## ファイル構成

### 1. **pubspec.yaml** - バージョン定義

```yaml
version: 1.0.0+1
```

このファイルに記載されたバージョンは、flutter pub get 時に確定され、すべての OS ビルドで一致します。

### 2. **scripts/bump_version.sh** - バージョン自動更新スクリプト

#### 使用方法

```bash
# patch 版をインクリメント（デフォルト）
./scripts/bump_version.sh

# minor 版をインクリメント
./scripts/bump_version.sh minor

# major 版をインクリメント
./scripts/bump_version.sh major
```

#### 動作

- pubspec.yaml の version フィールドを更新
- ビルド番号は以下のルールで管理
  - patch: 現在のビルド番号を +1
  - minor: 1 にリセット
  - major: 1 にリセット
- macOS・Linux 両対応の sed コマンド使用

### 3. **lib/ui/main_screen.dart** - UI 表示機能

#### バージョン取得メカニズム

```dart
void _loadPackageInfo() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  } catch (e) {
    debugPrint('Failed to load package info: $e');
  }
}
```

#### UI 表示

AppBar の右側（actions）に v1.0.0+1 形式で表示されます：

```dart
actions: [
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Center(
      child: Text(
        'v$_appVersion',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
        ),
      ),
    ),
  ),
]
```

## デプロイワークフロー

### 標準的なリリース手順

```bash
# 1. feature ブランチから main へのマージ確認
git checkout main
git pull origin main

# 2. バージョン更新スクリプトを実行
./scripts/bump_version.sh [major|minor|patch]

# 3. 変更を確認して commit
git diff pubspec.yaml
git add pubspec.yaml
git commit -m "bump: version update to X.Y.Z+N"

# 4. タグ付けしてプッシュ
git tag v1.0.0
git push origin main
git push origin --tags

# 5. ビルド・デプロイ
flutter build apk --release
flutter build ios --release
```

### CI/CD パイプラインでの統合（今後）

.github/workflows/release.yml で以下を自動化予定：
- バージョン更新スクリプト実行
- テスト実行確認
- ビルド実行
- リリースノート生成

## バージョン表示の確認

### アプリ起動時

1. アプリを起動します
2. AppBar 右上に v1.0.0+1 などのバージョン表示を確認
3. 非同期読み込みのため、初期表示はデフォルト値、その後動的更新

### コマンドラインでの確認

```bash
# pubspec.yaml から確認
grep "^version:" pubspec.yaml

# ビルド後の info.plist から確認（iOS）
grep -A1 CFBundleVersion ios/Runner/Info.plist

# AndroidManifest から確認（Android）
grep android:versionCode android/app/build.gradle.kts
```

## トラブルシューティング

### バージョンが UI に反映されない場合

1. **キャッシュをクリア**：
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **ホットリロードが機能しない場合**：
   - ホットリスタートを実行：R キー（コマンドラインから）
   - または アプリを完全に再起動

3. **package_info_plus が null を返す場合**：
   - `flutter clean` を実行
   - ビルド環境をリセット
   - 別のデバイス・エミュレータで確認

### スクリプト実行エラー

```bash
# 実行権限がない場合
chmod +x scripts/bump_version.sh

# sed コマンドエラー（BSD vs GNU）の場合
# macOS では既に対応済み（-i '' で処理）
```

## 関連ファイル

- [pubspec.yaml](../pubspec.yaml) - バージョン定義
- [scripts/bump_version.sh](../scripts/bump_version.sh) - 自動更新スクリプト
- [lib/ui/main_screen.dart](../lib/ui/main_screen.dart#L116) - UI 表示実装
- [docs/DEVELOPMENT.md](./DEVELOPMENT.md) - 開発フロー

## 今後の改善予定

1. **自動バージョン更新の CI/CD 統合**
   - GitHub Actions での自動実行
   - PR マージ時の自動バージョンアップ

2. **リリースノートの自動生成**
   - git commit メッセージからの抽出
   - CHANGELOG.md の自動更新

3. **バージョン互換性チェック**
   - ダウンストリーム依存関係の確認
   - API 互換性の検証

4. **マルチプラットフォーム対応強化**
   - Web ビルドでの version.json 更新
   - macOS/Windows ビルドのバージョン統一
