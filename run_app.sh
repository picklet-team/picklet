#!/bin/bash

# 設定項目（あなたの環境に合わせて変更）
SCHEME="MyApp"  # ← Xcodeのスキーム名
BUNDLE_ID="com.example.MyApp"  # ← あなたのアプリのバンドルID
DEVICE_UDID="926C9EF3-F840-444D-8361-6B802B550C23"

echo "🔄 シミュレータを起動中: iPhone 16 ($DEVICE_UDID)"
xcrun simctl boot "$DEVICE_UDID" || echo "🟡 既に起動済みかもしれません"

# ビルド
echo "🛠 アプリをビルド中..."
xcodebuild -scheme "$SCHEME" -destination "id=$DEVICE_UDID" build || {
    echo "❌ ビルド失敗"
    exit 1
}

# .app の場所を自動で探す（最も最近のビルド）
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -type d -name "$SCHEME.app" | sort -r | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ .app が見つかりません"
    exit 1
fi

# インストールと起動
echo "📲 アプリをシミュレータにインストール: $APP_PATH"
xcrun simctl install "$DEVICE_UDID" "$APP_PATH"

echo "🚀 アプリを起動: $BUNDLE_ID"
xcrun simctl launch "$DEVICE_UDID" "$BUNDLE_ID"

