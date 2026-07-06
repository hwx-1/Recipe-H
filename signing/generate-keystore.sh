#!/bin/bash
# 手动生成 HarmonyOS 调试密钥库(debug.p12)
# 用法：bash signing/generate-keystore.sh

set -e
KEYTOOL="/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home/bin/keytool"
mkdir -p signing

"$KEYTOOL" -genkeypair \
  -alias "debugKey" \
  -groupname secp256r1 \
  -sigalg SHA256withECDSA \
  -validity 3650 \
  -keystore signing/debug.p12 \
  -storetype PKCS12 \
  -storepass "NeLogismRecipe123" \
  -keypass "NeLogismRecipe123" \
  -dname "CN=NeLogismRecipe Debug, OU=Dev, O=xinyu, C=CN"

echo ""
echo "✅ 密钥库已生成: signing/debug.p12"
echo ""
echo "SHA-256 指纹（请添加到 AGC 控制台）:"
"$KEYTOOL" -list -v -keystore signing/debug.p12 -storepass "NeLogismRecipe123" | grep "SHA256:"
