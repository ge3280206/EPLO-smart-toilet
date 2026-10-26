#!/bin/bash
# 在 Mac 上一键产出 EPLOSmart-unsigned.ipa（无需开发者账号）
# 用法：双击终端执行  ./build_ipa.sh
set -e

cd "$(dirname "$0")"

echo "==> 清理旧产物"
rm -rf build Payload EPLOSmart-unsigned.ipa

echo "==> 编译（关闭代码签名）"
xcodebuild \
  -project EPLOiOS.xcodeproj \
  -scheme EPLOiOS \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "==> 打包成 .ipa"
mkdir -p Payload
APP_PATH=$(find build/Build/Products/Release-iphoneos -maxdepth 1 -name "*.app" | head -n 1)
echo "    找到：$APP_PATH"
cp -R "$APP_PATH" Payload/
zip -r EPLOSmart-unsigned.ipa Payload

echo "==> 完成：$(pwd)/EPLOSmart-unsigned.ipa"
echo "    把这个文件拷到 Windows，用 Sideloadly + 你的 Apple ID 自签安装到 iPhone。"
