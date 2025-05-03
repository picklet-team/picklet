#!/bin/bash

# === 必須設定 ===============================
SCHEME="Picklet"                      # あなたのXcodeのスキーム名に変更
BUNDLE_ID="Reiji.Picklet"       # あなたのアプリのバンドルIDに変更
DEVICE_UDID="00008101-000968C90E28001E" # あなたのiPhoneのUDIDに差し替え
# ============================================

echo "🔧 実機ビルド＆インストール開始（UDID: $DEVICE_UDID）"

# ビルド＆署名（プロビジョニングプロファイル自動対応）
xcodebuild -scheme "$SCHEME" \
  -destination "platform=iOS,id=$DEVICE_UDID" \
  -allowProvisioningUpdates \
  build || {
    echo "❌ ビルドに失敗しました"
    exit 1
}

# .app の検索（最新のビルド成果物）
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "$SCHEME.app" | sort -r | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ .app が見つかりません"
    exit 1
fi

echo "📲 インストール中: $APP_PATH"
xcrun simctl install "$DEVICE_UDID" "$APP_PATH" || {
    echo "❌ インストールに失敗しました"
    exit 1
}

echo "🚀 起動中: $BUNDLE_ID"
xcrun simctl launch "$DEVICE_UDID" "$BUNDLE_ID" || {
    echo "❌ 起動に失敗しました"
    exit 1
}

