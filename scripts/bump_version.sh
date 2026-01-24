#!/bin/bash

# バージョン自動更新スクリプト
# 使用方法: ./scripts/bump_version.sh [major|minor|patch]
# デフォルト: patch版を自動インクリメント

set -e

PUBSPEC_FILE="pubspec.yaml"

# 現在のバージョンを取得
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | awk '{print $2}')

# バージョンとビルド番号を安全に分割
if [[ "$CURRENT_VERSION" == *+* ]]; then
  VERSION_PART="${CURRENT_VERSION%+*}"   # + の前の部分
  BUILD_NUMBER="${CURRENT_VERSION##*+}"  # + の後の部分
else
  VERSION_PART="$CURRENT_VERSION"
  BUILD_NUMBER=0
fi

# バージョンパーツ情報
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_PART"

# オプション指定があればそれに従う
case "${1:-patch}" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    BUILD_NUMBER=1
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    BUILD_NUMBER=1
    ;;
  patch)
    PATCH=$((PATCH + 1))
    BUILD_NUMBER=$((BUILD_NUMBER + 1))
    ;;
  *)
    echo "使用方法: $0 [major|minor|patch]"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_NUMBER"

echo "バージョン更新: $CURRENT_VERSION → $NEW_VERSION"

# pubspec.yaml を更新
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
else
  # Linux
  sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
fi

echo "✓ $PUBSPEC_FILE を更新しました"
echo "新バージョン: $NEW_VERSION"
