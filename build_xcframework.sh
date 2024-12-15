#!/bin/bash

# スクリプトがエラーで停止するように設定
set -e

# プロジェクト名とバージョンを設定
PROJECT_NAME="CxxLibSample"
VERSION="1.0.0"

# ios-cmake のクローン先ディレクトリ
IOS_CMAKE_DIR="ios-cmake"

# スクリプトの実行ディレクトリをプロジェクトルートに設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ios-cmake が存在しない場合はクローン
if [ ! -d "$IOS_CMAKE_DIR" ]; then
    echo "ios-cmake が見つかりません。クローンします..."
    git clone https://github.com/leetal/ios-cmake.git "$IOS_CMAKE_DIR"
else
    echo "ios-cmake が既に存在します。"
fi

# ビルドディレクトリの作成
BUILD_DIR="$SCRIPT_DIR/build"
IOS_ARM64_BUILD_DIR="$BUILD_DIR/ios_arm64"
IOS_SIM_ARM64_BUILD_DIR="$BUILD_DIR/ios_sim_arm64"
XCFRAMEWORK_DIR="$BUILD_DIR/xcframework"

mkdir -p "$IOS_ARM64_BUILD_DIR" "$IOS_SIM_ARM64_BUILD_DIR" "$XCFRAMEWORK_DIR"

# 共通設定
CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=Release"

# C++標準（必要に応じて変更）
CMAKE_OPTIONS="$CMAKE_OPTIONS -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=YES"

# ヘッダーファイルのパス（必要に応じて変更）
HEADERS_DIR="$SCRIPT_DIR/include"

# 1. iOS実機（arm64）向けのビルド
echo "iOS実機（arm64）向けにビルド中..."
cmake -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/$IOS_CMAKE_DIR/ios.toolchain.cmake" \
    -DPLATFORM=OS64 \
    $CMAKE_OPTIONS \
    -B "$IOS_ARM64_BUILD_DIR" \
    -S "$SCRIPT_DIR"

cmake --build "$IOS_ARM64_BUILD_DIR" --config Release

# 2. iOSシミュレータ（arm64）向けのビルド
echo "iOSシミュレータ（arm64）向けにビルド中..."
cmake -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/$IOS_CMAKE_DIR/ios.toolchain.cmake" \
    -DPLATFORM=SIMULATORARM64 \
    $CMAKE_OPTIONS \
    -B "$IOS_SIM_ARM64_BUILD_DIR" \
    -S "$SCRIPT_DIR"

cmake --build "$IOS_SIM_ARM64_BUILD_DIR" --config Release

# ビルドされたライブラリのパスを設定
IOS_ARM64_LIB="$IOS_ARM64_BUILD_DIR/Release-iphoneos/lib${PROJECT_NAME}.a"
IOS_SIM_ARM64_LIB="$IOS_SIM_ARM64_BUILD_DIR/Release-iphonesimulator/lib${PROJECT_NAME}.a"

# XCFramework作成の前に存在確認
if [ ! -f "$IOS_ARM64_LIB" ]; then
    echo "エラー: $IOS_ARM64_LIB が存在しません。ビルドが成功したか確認してください。"
    exit 1
fi

if [ ! -f "$IOS_SIM_ARM64_LIB" ]; then
    echo "エラー: $IOS_SIM_ARM64_LIB が存在しません。ビルドが成功したか確認してください。"
    exit 1
fi

# 3. XCFrameworkの作成
echo "XCFrameworkを作成中..."
xcodebuild -create-xcframework \
    -library "$IOS_ARM64_LIB" \
    -headers "$HEADERS_DIR" \
    -library "$IOS_SIM_ARM64_LIB" \
    -headers "$HEADERS_DIR" \
    -output "$XCFRAMEWORK_DIR/${PROJECT_NAME}.xcframework"

echo "XCFrameworkが作成されました: $XCFRAMEWORK_DIR/${PROJECT_NAME}.xcframework"

# rm -rf "$BUILD_DIR/ios_arm64" "$BUILD_DIR/ios_sim_arm64"

echo "完了しました。"
