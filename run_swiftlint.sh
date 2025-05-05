#!/bin/bash

# SwiftLintがインストールされているか確認
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  echo "または以下のコマンドでインストールしてください:"
  echo "brew install swiftlint"
fi