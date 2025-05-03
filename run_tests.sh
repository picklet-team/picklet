#!/bin/bash

echo "🔄 Pickletプロジェクトのテスト実行スクリプト"

# OSのタイプを判定
OS_TYPE=$(uname)
echo "🖥️ 実行環境: $OS_TYPE"

if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS環境での実行
    echo "🍎 macOS環境でのテスト実行"
    
    # Xcodeのユニットテスト実行
    echo "🧪 Xcodeテスト実行中..."
    xcodebuild test \
        -project Picklet.xcodeproj \
        -scheme Picklet \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -resultBundlePath TestResults
    
    TEST_RESULT=$?
    
elif [[ "$OS_TYPE" == "Linux" ]]; then
    # Linux環境での実行 (Swift Package Managerが必要)
    echo "🐧 Linux環境でのテスト実行"
    
    # Swift Package Managerの確認
    if ! command -v swift &> /dev/null; then
        echo "❌ Swiftがインストールされていません。Swift Package Managerが必要です。"
        exit 1
    fi
    
    # Swift Package Managerを使用してテストを実行
    echo "🔄 Swift Package Managerを設定中..."
    
    # Swift Package Managerの設定ファイルが存在しない場合は作成
    if [ ! -f "Package.swift" ]; then
        echo "📦 Package.swiftを作成中..."
        cat > Package.swift <<EOF
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Picklet",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Picklet", targets: ["Picklet"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Picklet", dependencies: [], path: "Picklet"),
        .testTarget(name: "PickletTests", dependencies: ["Picklet"], path: "PickletTests"),
    ]
)
EOF
    fi
    
    # テスト実行
    echo "🧪 Swift Package Managerでテスト実行中..."
    swift test --enable-test-discovery
    
    TEST_RESULT=$?
    
else
    echo "❌ サポートされていないOS: $OS_TYPE"
    exit 1
fi

# テスト結果の確認
if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ テスト成功!"
else
    echo "❌ テスト失敗!"
    exit 1
fi

echo "🏁 テスト実行完了"