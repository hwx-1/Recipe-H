# 调试签名文件说明

本目录存放 **调试证书** 相关文件，均已加入 `.gitignore`，不会提交到 Git。

## 当前已生成

| 文件 | 说明 |
|------|------|
| `debug.p12` | 调试密钥库（密码见下） |
| `debug.csr` | 待上传到 AGC 申请证书（若未生成，运行 `bash signing/generate-csr.sh`） |

**密钥库密码**：`NeLogismRecipe123`（本地调试用，勿用于正式发布）

## 你的 SHA-256 指纹（添加到 AGC）

```
E4:89:D5:C2:E6:85:F5:8C:96:BB:B3:4F:76:70:B3:A4:1D:D9:DC:A3:E0:D4:6C:23:D8:90:C3:F3:47:89:1F:1C
```

AGC 路径：**项目设置 → 常规 → 应用 → SHA256证书/公钥指纹 → 添加**

## 申请 .cer 和 .p7b（HarmonyOS 打包必需）

1. 运行 `bash signing/generate-csr.sh` 生成 CSR
2. AGC → **项目设置 → 常规 → 应用 → 证书**
3. **新增调试证书** → 上传 `signing/debug.csr`
4. 下载得到的 **`.cer`** 和 **`.p7b`**，放到本目录：
   - `signing/debug.cer`
   - `signing/debug.p7b`
5. 在 DevEco 中 **Sync Project**，重新 Run

## 无真机：使用本地模拟器

1. DevEco → **Tools → Device Manager → Local Emulator**
2. 创建 **Phone** 模拟器（API 24）
3. 模拟器内 **设置 → 登录华为账号**（Account Kit 需要）
4. 选择模拟器作为 Run 目标
