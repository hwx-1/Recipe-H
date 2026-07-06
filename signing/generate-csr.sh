#!/bin/bash
# 生成 CSR 文件，用于在 AGC 控制台申请调试证书(.cer + .p7b)
# 用法：在项目根目录执行 bash signing/generate-csr.sh

set -e
KEYTOOL="/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home/bin/keytool"
STORE="signing/debug.p12"
PASS="NeLogismRecipe123"

if [ ! -f "$STORE" ]; then
  echo "未找到 $STORE，请先运行 signing/generate-keystore.sh"
  exit 1
fi

"$KEYTOOL" -certreq -alias debugKey -keystore "$STORE" -storepass "$PASS" -file signing/debug.csr
echo "✅ CSR 已生成: signing/debug.csr"
echo "下一步：上传到 AGC → 项目设置 → 常规 → 应用 → 证书 → 申请调试证书"
