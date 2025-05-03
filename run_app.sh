#!/bin/bash

# 設定項目（あなたの環境に合わせて変更）
SCHEME="Picklet"  # ← 利用可能なスキーム名に戻す
BUNDLE_ID="Reiji.Picklet"  # ← あなたのアプリのバンドルID
DEVICE_UDID="926C9EF3-F840-444D-8361-6B802B550C23"

echo "🔄 シミュレータを起動中: iPhone 16 ($DEVICE_UDID)"
xcrun simctl boot "$DEVICE_UDID" || echo "🟡 既に起動済みかもしれません"

# スキーム名を明示的に出力（デバッグ用）
echo "👉 使用するスキーム: $SCHEME"

# ビルド
echo "🛠 アプリをビルド中..."
xcodebuild -scheme "$SCHEME" -destination "id=$DEVICE_UDID" build || {
    echo "❌ ビルド失敗"
    exit 1
}

# .app の場所を自動で探す（最も最近のビルド）
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -path "*/Build/Products/Debug-iphonesimulator/Picklet.app" | sort -r | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Picklet.app が見つかりません"
    
    # 代替検索パスを試す
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Picklet.app" | grep -v "Index\.noindex" | sort -r | head -n 1)
    
    if [ -z "$APP_PATH" ]; then
        echo "❌ 代替検索でも Picklet.app が見つかりません"
        exit 1
    fi
fi

echo "✅ アプリパス: $APP_PATH"

# Info.plist をチェック
echo "🔍 Info.plist の内容を確認します..."
plutil -p "$APP_PATH/Info.plist"

# インストールと起動
echo "📲 アプリをシミュレータにインストール: $APP_PATH"
xcrun simctl install "$DEVICE_UDID" "$APP_PATH"

echo "🚀 アプリを起動: $BUNDLE_ID"
xcrun simctl launch "$DEVICE_UDID" "$BUNDLE_ID"

