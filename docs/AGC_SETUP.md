# 心语食记 · AGC / 华为账号 / 云服务接入指南

> **适用身份**：个人独立开发者（无需企业认证）  
> **当前工程**：`bundleName = com.xinyu.recipe`，HarmonyOS API 24  
> **预计耗时**：首次配置约 1～2 小时（含实名认证等待）

---

## 一、你需要准备什么

| 项目 | 说明 |
|------|------|
| 华为账号 | 用于登录开发者联盟 |
| 身份证 | 个人开发者实名认证 |
| 华为手机 / 模拟器 | 设备需登录华为账号才能测登录 |
| DevEco Studio | 已打开本工程 `NeLogismRecipe` |

---

## 二、整体架构（本 App 怎么用）

```
用户点击「华为账号登录」
        │
        ▼
Account Kit（系统 Kit）
  → 获取 UnionID / 昵称 / 头像
        │
        ▼
AGC 认证服务（@hw-agconnect/auth）
  → signIn({ kind: 'hwid' }) 换取云侧身份
        │
        ▼
Cloud Foundation Kit 初始化
  → 后续 Cloud DB / Cloud Storage 自动带用户凭证
```

**个人开发者可用**：
- ✅ 华为账号标准登录（UnionID）
- ✅ 静默登录
- ✅ AGC 认证 + 云数据库 + 云存储
- ❌ 一键登录拿手机号（仅企业开发者）

---

## 三、Step 1 — 注册华为开发者（必做）

1. 打开 [华为开发者联盟](https://developer.huawei.com/consumer/cn/)
2. 点击 **注册** → 选择 **个人开发者**
3. 完成 **实名认证**（身份证 + 人脸识别）
4. 认证通过后进入 **AppGallery Connect**：[https://developer.huawei.com/consumer/cn/service/josp/agc/index.html](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)

---

## 四、Step 2 — 在 AGC 创建项目与应用

### 4.1 创建项目

1. AGC 控制台 → **我的项目** → **添加项目**
2. 项目名称：`心语食记`（随意）
3. 数据处理位置：选 **中国**（Cloud DB 区域需一致）

### 4.2 添加 HarmonyOS 应用

1. 项目中 → **添加应用** → 平台选 **HarmonyOS**
2. **包名必须填**：`com.xinyu.recipe`（与 `AppScope/app.json5` 中 `bundleName` 一致，改包名需两边同步）
3. 应用名称：`心语食记`
4. 记录以下信息（后面要用）：

| 字段 | 在哪里看 | 用途 |
|------|----------|------|
| **App ID** | 项目设置 → 常规 → 应用 | AGC 应用标识 |
| **Client ID** | 项目设置 → 常规 → 应用 → OAuth 2.0 客户端 ID | 写入 `module.json5` |
| **Client Secret** | 同上（点击显示） | 仅服务端用；纯客户端云开发可不写进 App |
| **API 密钥** | 项目设置 → 常规 → API 密钥 | 云函数等场景 |

---

## 五、Step 3 — 开通所需服务（AGC 控制台）

在 **构建** 或 **开发与服务** 中依次开通：

| 服务 | 路径 | 用途 |
|------|------|------|
| **Account Kit** | 开放能力 / Account Kit | 华为账号登录 |
| **认证服务** | 构建 → 认证服务 → 启用 | 云侧用户身份 |
| **云数据库 Cloud DB** | 构建 → 云数据库 → 创建 | 情侣空间 / 任务 / 排行 |
| **云存储 Cloud Storage** | 构建 → 云存储 → 启用 | 打卡照片 |
| **Push Kit**（可选 v1.1） | 构建 → Push Kit | 推送通知 |

### 5.1 认证服务 — 启用华为账号

1. **认证服务** → **认证方式** → 开启 **华为账号**
2. 保存

### 5.2 云数据库 — 创建实例

1. **云数据库** → **创建 Cloud DB 区域** → 选 **中国**
2. **对象类型** → 后续在 DevEco 用 **端云一体化** 或手动导入 schema（开发阶段可先建空库）
3. **存储区** → 创建 zone，名称建议：`RecipeSpace`（与代码中常量一致）
4. **权限** → 每个对象类型需配置规则，例如：
   - `CoupleSpace`：`memberIds has [auth.uid]`
   - `SpaceTask`：读写仅限空间成员（接入后再细配）

### 5.3 云存储 — 启用

1. **云存储** → 启用默认存储实例
2. **安全规则**（后续配置）：仅认证用户可读写自己的空间路径

---

## 六、Step 4 — 配置签名证书指纹（最容易踩坑）

Account Kit **必须**配置 SHA-256 指纹，否则点击登录报错。

### 4.1 在 DevEco 生成调试证书

1. DevEco Studio → **File → Project Structure → Signing Configs**
2. 勾选 **Automatically generate signature**（调试）或手动创建
3. 生成后找到 **SHA-256 证书指纹**

或使用命令（证书路径按你本机调整）：

```bash
keytool -list -v -keystore ~/.ohos/config/auto_debug_*.p12 -storetype PKCS12
```

### 4.2 上传到 AGC

1. AGC → **项目设置 → 常规 → 应用**
2. **SHA256 证书/公钥指纹** → **添加公钥指纹（HarmonyOS API 9 及以上）**
3. 粘贴 **SHA-256** 值（去掉冒号或保留，按控制台提示）
4. **调试证书**和**发布证书**都要分别添加（上架前必须加发布指纹）

---

## 七、Step 5 — 下载配置文件

1. AGC → **项目设置 → 常规**
2. 点击 **agconnect-services.json** 下载
3. 复制到工程：

```
AppScope/resources/rawfile/agconnect-services.json
```

⚠️ **此文件含 Client Secret 等敏感信息，不要提交到公开 Git**（已在 `.gitignore` 忽略）。  
仓库内提供了 `agconnect-services.json.template` 作结构参考。

---

## 八、Step 6 — 修改工程配置（你要改的唯一几处）

### 6.1 填写 Client ID

编辑 `entry/src/main/module.json5`，将：

```json
"value": "YOUR_AGC_CLIENT_ID"
```

替换为 AGC 控制台复制的 **Client ID**（纯数字字符串）。

> 必须使用字面量，**不要**用 `$r('app.string.xxx')` 引用。

### 6.2 安装 AGC 依赖

在 DevEco 终端执行：

```bash
cd entry
ohpm install @hw-agconnect/hmcore
ohpm install @hw-agconnect/auth
```

（根目录也可执行 `ohpm install`，以 DevEco 同步为准）

### 6.3 自动签名

DevEco → **File → Project Structure → Signing Configs** → 调试签名启用。

---

## 九、Step 7 — 验证登录是否成功

1. 用 **华为手机**或模拟器（需登录华为账号）
2. DevEco **Run** 安装 App
3. 首次启动 → 同意协议 → 进入 **我的 → 点击登录**
4. 勾选协议 → 点击 **华为账号登录**
5. 成功标志：
   - 显示昵称 / 头像
   - Log 出现 `AccountService: signIn success, unionId=...`
   - Log 出现 `AgcInitializer: AGC initialized`

### 常见错误

| 错误码 / 现象 | 原因 | 解决 |
|---------------|------|------|
| 无响应 / 100xxx | 未配置 `client_id` | 检查 module.json5 |
| 1001502001 等 | SHA-256 指纹未配 | AGC 添加调试指纹 |
| agconnect 初始化失败 | json 未放置或路径错 | 确认 rawfile 路径 |
| 认证 signIn 失败 | 认证服务未开华为账号 | AGC 认证服务开启 hwid |
| 云数据库 Permission Denied | DB 规则或 zone 名不对 | 检查 zone 名与权限 |

---

## 十、Step 8 — 云数据库对象类型（后续开发用）

建议在 AGC Cloud DB 创建以下对象（字段可后续迭代）：

| 对象 | 主要字段 | 说明 |
|------|----------|------|
| `RecipeStats` | recipeId, forwardCount, likeCount | 全局排行 |
| `RecipeLike` | userId, recipeId | 用户点赞 |
| `RecipeForwardLog` | userId, spaceId, recipeId, at | 转发记录 |
| `CoupleSpace` | id, memberIds[], status | 情侣空间 |
| `SpaceFeedItem` | type, recipeId, sharerId, phraseId, at | 空间动态 |
| `SpaceTask` | type, title, status, ... | 待办任务 |

权限模板（示例）：

```
read: auth != null
write: auth != null && (memberIds has auth.uid)
```

---

## 十一、你需要发给我的信息（可选，便于我帮你改代码）

配置完成后，如果登录仍有问题，请提供：

1. ✅ 是否已完成实名认证
2. ✅ Client ID（可打码中间几位）
3. ✅ 是否已放置 `agconnect-services.json`
4. ✅ 是否已添加 SHA-256 调试指纹
5. ❌ **不要**发 Client Secret / API 密钥给我

---

## 十二、官方文档链接

| 文档 | 链接 |
|------|------|
| 配置 Client ID | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-configuration-client-id |
| Account Kit 华为账号登录 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-unionid-login |
| AGC 认证服务 | https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-auth-introduction-0000001050169407 |
| 云数据库 | https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-clouddb-harmonyos-introduction-0000000000037728 |
| 云存储 | https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-cloudstorage-introduction-0000000000037726 |

---

## 十三、检查清单（打印自用）

```
[ ] 个人开发者实名认证通过
[ ] AGC 项目已创建，包名 com.xinyu.recipe
[ ] Account Kit 已启用
[ ] 认证服务 → 华为账号 已开启
[ ] 云数据库 zone 已创建（中国）
[ ] 云存储已启用
[ ] SHA-256 调试指纹已添加到 AGC
[ ] agconnect-services.json 已放到 AppScope/resources/rawfile/
[ ] module.json5 中 client_id 已替换为真实 Client ID
[ ] ohpm install 已执行
[ ] 真机/模拟器已登录华为账号
[ ] App 内登录成功，UnionID 有值
```

全部打勾后，即可继续开发：**情侣绑定、Cloud DB 任务、打卡上传**。

---

## 十四、无真机调试：手动证书 + 本地模拟器（本项目已配置）

### 14.1 已写入工程的配置

| 项 | 值 / 位置 |
|----|-----------|
| Client ID | `1988530467258815232` → `entry/src/main/module.json5` |
| agconnect-services.json | `AppScope/resources/rawfile/`（已 gitignore） |
| 调试密钥库 | `signing/debug.p12` |
| 签名配置 | 根目录 `build-profile.json5` |

### 14.2 你必须做的 3 步

#### ① 添加 SHA-256 指纹到 AGC

在 AGC → **项目设置 → 常规 → 应用 → SHA256证书/公钥指纹** 添加：

```
E4:89:D5:C2:E6:85:F5:8C:96:BB:B3:4F:76:70:B3:A4:1D:D9:DC:A3:E0:D4:6C:23:D8:90:C3:F3:47:89:1F:1C
```

#### ② 申请调试证书（.cer + .p7b）

HarmonyOS 打包**必须**有 AGC 签发的证书，仅有 p12 不够：

1. 终端执行：`bash signing/generate-csr.sh`
2. AGC → **项目设置 → 常规 → 应用 → 证书 → 新增调试证书**
3. 上传 `signing/debug.csr`
4. 下载 **debug.cer** 和 **debug.p7b** 到 `signing/` 目录
5. DevEco **Sync Project** 后重新 Run

#### ③ 使用本地模拟器（无真机）

1. DevEco → **Tools → Device Manager → Local Emulator**
2. 新建 Phone 模拟器（API 24）
3. 启动模拟器 → **设置 → 登录华为账号**
4. Run 目标选该模拟器

### 14.3 建议从 AGC 重新下载 agconnect-services.json

若 AGC 初始化报错，请在 AGC 控制台 **项目设置 → 常规** 重新下载官方
`agconnect-services.json`，覆盖 `AppScope/resources/rawfile/` 下文件（含正确的 cp_id、project_id）。

### 14.4 安全提醒

- **Client Secret / API 密钥** 仅存在于 gitignore 的 json 中，**切勿提交 Git 或公开分享**
- 若密钥已在聊天/论坛泄露，建议在 AGC 控制台 **重置 Client Secret**

---

## 十五、云数据库 & 云存储详细操作（接 Cloud DB / Storage 必读）

> **适用阶段**：华为账号登录 + 认证服务已成功（Log 出现 `signIn success` 且 `CloudFoundationKit initialized`）  
> **数据处理位置**：Cloud DB 与 Cloud Storage 均选 **中国**，且与项目设置一致

### 15.1 前置条件

| 项 | 要求 |
|------|------|
| 实名认证 | 个人开发者已通过 |
| 包名 | `com.xinyu.recipe` |
| 认证服务 | 已开启 **华为账号** |
| 配置文件 | `AppScope/resources/rawfile/agconnect-services.json` 已放置 |
| Client ID | `entry/src/main/module.json5` 已填写 |
| SHA-256 | 调试指纹已添加到 AGC |

---

### 15.2 云数据库 Cloud DB

#### 15.2.1 开通与创建存储区

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 进入项目 **心语食记** → 应用 **心语食记 (HarmonyOS)**
3. 左侧菜单（新版可能在 **云开发 Serverless** 下）：
   - **构建 → 云数据库**，或 **云开发 → 云数据库**
4. **创建 Cloud DB 区域** → 区域选 **中国**
5. **创建存储区（CloudDBZone）**
   - 名称：`RecipeSpace`（与代码规划一致，**创建后不可改名**）
   - 说明：情侣空间、任务、排行等业务数据均放此 zone

> 一个应用可有多个存储区；本项目 MVP 仅用一个 `RecipeSpace`。

#### 15.2.2 创建对象类型（7 张「表」）

在 **云数据库 → 对象类型 → 新增** 逐个创建。  
命名规则：字母开头，仅含字母、数字、下划线。

##### ① CoupleSpace（情侣空间）

| 字段名 | 类型 | 主键 | 非空 | 说明 |
|--------|------|------|------|------|
| `id` | String | ✅ | ✅ | 空间 ID，如 `space_xxx` |
| `memberId1` | String | | ✅ | 成员 A 的 UnionID |
| `memberId2` | String | | | 成员 B（绑定前可空） |
| `status` | String | | ✅ | `pending` / `active` / `archived` |
| `createdAt` | Long | | ✅ | 毫秒时间戳 |
| `updatedAt` | Long | | ✅ | 毫秒时间戳 |

**建议索引**：`memberId1`、`memberId2`

> Cloud DB 不原生支持 `String[]`，用两个成员字段代替本地模型的 `memberIds[]`，客户端组装成数组。

##### ② PendingInvite（邀请码）

| 字段名 | 类型 | 主键 | 非空 | 说明 |
|--------|------|------|------|------|
| `code` | String | ✅ | ✅ | 如 `LOVE-8848` |
| `spaceId` | String | | ✅ | 关联空间 |
| `creatorId` | String | | ✅ | 发起人 UnionID |
| `creatorName` | String | | | 昵称 |
| `expiresAt` | Long | | ✅ | 过期时间（7 天） |
| `createdAt` | Long | | ✅ | 创建时间 |

**建议索引**：`spaceId`、`creatorId`

##### ③ SpaceFeedItem（空间动态）

| 字段名 | 类型 | 主键 | 非空 | 说明 |
|--------|------|------|------|------|
| `id` | String | ✅ | ✅ | 动态 ID |
| `spaceId` | String | | ✅ | 所属空间 |
| `sharerId` | String | | ✅ | 转发人 UnionID |
| `recipeId` | String | | ✅ | 食谱 ID |
| `recipeTitle` | String | | ✅ | 菜名（冗余，少查一次） |
| `presetPhrase` | String | | ✅ | 预设转发语 |
| `createdAt` | Long | | ✅ | 创建时间 |
| `isRead` | Boolean | | ✅ | 对方是否已读 |

**建议索引**：`spaceId`、`createdAt`（降序查动态）

##### ④ SpaceTask（空间任务）

| 字段名 | 类型 | 主键 | 非空 | 说明 |
|--------|------|------|------|------|
| `id` | String | ✅ | ✅ | 任务 ID |
| `spaceId` | String | | ✅ | 所属空间 |
| `creatorId` | String | | ✅ | 创建人 |
| `assigneeId` | String | | | 接取人 |
| `type` | String | | ✅ | `craving`/`errand`/`recipe_done`/`daily_pact`/`custom` |
| `title` | String | | ✅ | 标题 |
| `description` | Text | | | 描述 |
| `relatedRecipeId` | String | | | 关联食谱 |
| `status` | String | | ✅ | `open`/`doing`/`done`/`praised` |
| `checkInPhotoUrl` | String | | | 打卡图 Cloud Storage URL |
| `praiseText` | String | | | 夸赞文案 |
| `praisedBy` | String | | | 夸赞人 UnionID |
| `createdAt` | Long | | ✅ | 创建时间 |
| `updatedAt` | Long | | ✅ | 更新时间 |
| `isRead` | Boolean | | ✅ | 未读标记 |

**建议索引**：`spaceId`、`status`、`updatedAt`

##### ⑤ RecipeStats（全局统计 / 排行）

| 字段名 | 类型 | 主键 | 非空 | 说明 |
|--------|------|------|------|------|
| `recipeId` | String | ✅ | ✅ | 食谱 ID |
| `forwardCount` | Integer | | ✅ | 转发量 |
| `likeCount` | Integer | | ✅ | 点赞量 |
| `updatedAt` | Long | | ✅ | 最后更新时间 |

**建议索引**：`forwardCount`、`likeCount`（排行查询）

##### ⑥ RecipeLike（用户点赞记录）

| 字段名 | 类型 | 主键 | 非空 | 说明 |
|--------|------|------|------|------|
| `id` | String | ✅ | ✅ | 建议 `unionId_recipeId` |
| `userId` | String | | ✅ | UnionID |
| `recipeId` | String | | ✅ | 食谱 ID |
| `createdAt` | Long | | ✅ | 点赞时间 |

**建议索引**：`userId`、`recipeId`

##### ⑦ UserFavorite（用户收藏，可选）

| 字段名 | 类型 | 主键 | 非空 | 说明 |
|--------|------|------|------|------|
| `id` | String | ✅ | ✅ | `unionId_recipeId` |
| `userId` | String | | ✅ | UnionID |
| `recipeId` | String | | ✅ | 食谱 ID |
| `createdAt` | Long | | ✅ | 收藏时间 |

#### 15.2.3 权限配置（开发阶段推荐）

每个对象类型 → **权限** 页，按角色勾选：

| 对象 | World（所有人） | Authenticated（认证用户） | Creator（创建者） |
|------|-----------------|---------------------------|-------------------|
| **RecipeStats** | Read ✅ | Read ✅ Upsert ✅ | Delete ❌ |
| **RecipeLike** | Read ❌ | Read ✅ Upsert ✅ | Read ✅ Upsert ✅ Delete ✅ |
| **UserFavorite** | Read ❌ | Read ✅ Upsert ✅ | Read ✅ Upsert ✅ Delete ✅ |
| **CoupleSpace** | Read ❌ | Read ✅ Upsert ✅ | Delete ❌ |
| **PendingInvite** | Read ❌ | Read ✅ Upsert ✅ Delete ✅ | Delete ✅ |
| **SpaceFeedItem** | Read ❌ | Read ✅ Upsert ✅ | Delete ❌ |
| **SpaceTask** | Read ❌ | Read ✅ Upsert ✅ | Delete ❌ |

**说明：**

- **开发调试期**：Authenticated 给 Read + Upsert 即可，避免频繁 Permission Denied
- **正式上线后**：Cloud DB **不允许修改已有对象类型的权限**，上架前需定稿
- 情侣「仅成员可读写」在 AGC 原生角色里不易表达，MVP 靠 **客户端按 spaceId 过滤**；严格隔离需后续加 **云函数** 校验
- **不要**给 World 开 Upsert/Delete

#### 15.2.4 导出 Schema 到工程

1. 对象类型全部建完后 → **导出** → 格式选 **JSON**
2. 保存到工程（后续接 Cloud DB SDK 时使用）：

```
entry/src/main/resources/rawfile/clouddb/schema.json
```

或端云一体化工程路径：

```
CloudProgram/clouddb/objecttype/*.json
```

3. 记录 **schemaVersion**（如 `1`）；后续只能 **新增字段 / 新增对象类型**，不能删改已有字段类型

#### 15.2.5 发布对象类型到云端

1. **云数据库 → 存储区 RecipeSpace**
2. 确认对象类型已关联到该存储区
3. 点击 **部署 / 发布**（控制台可能显示「部署到云端」）
4. 等状态变为 **已部署 / 可用**

未部署时，客户端 `openCloudDBZone('RecipeSpace')` 会失败。

#### 15.2.6 检查 agconnect-services.json（Cloud DB 段）

重新下载 **项目设置 → 常规 → agconnect-services.json**，确认含 Cloud DB 配置，类似：

```json
"clouddb": {
  "defaultZone": "RecipeSpace",
  "zones": [
    {
      "zoneName": "RecipeSpace",
      "schemaVersion": 1
    }
  ]
}
```

若没有 `clouddb` 段 → 先完成 DB 区域 + 存储区创建，再重新下载 json。

#### 15.2.7 客户端依赖（接代码时）

当前工程已有 `@hw-agconnect/hmcore` + `@hw-agconnect/auth`，Cloud DB 还需：

```bash
cd entry
ohpm install @hw-agconnect/clouddb
```

初始化顺序（与现有代码一致）：

```
AccountService.signIn()
  → AgcInitializer.init()
  → CloudService.initCloud()   // CloudFoundationKit + authProvider
  → 打开 zone: RecipeSpace
  → SpaceRepository / RecipeStatsRepository 改读写 Cloud DB
```

---

### 15.3 云存储 Cloud Storage

用途：**任务打卡照片**（写入 `SpaceTask.checkInPhotoUrl`）。

#### 15.3.1 开通服务

1. AGC → **构建 → 云存储**（或 **云开发 → 云存储**）
2. 点击 **立即开通**
3. 填写：
   - **存储实例名称**：`xinyu-recipe`（小写+中划线，3～57 字符，**全局唯一、不可改**）
   - **数据处理位置**：**中国**
4. 下一步 → 默认安全策略 → **完成**

#### 15.3.2 目录规划（建议）

| 路径 | 用途 | 访问 |
|------|------|------|
| `spaces/{spaceId}/checkin/{taskId}/{fileName}.jpg` | 任务打卡图 | 仅空间成员 |
| `users/{unionId}/avatar/` | 头像缓存（可选） | 仅本人 |

示例完整路径：

```
spaces/space_abc123/checkin/task_xyz/20260706_001.jpg
```

上传成功后，将返回的 **downloadUrl / cloudPath** 写入 `SpaceTask.checkInPhotoUrl`。

#### 15.3.3 安全规则（开发 → 上线）

开通时会展示默认策略，通常类似「仅认证用户可读写」。

**开发调试（简单）：**

```
agc.cloud.storage[
  match: /{path=**} {
    allow read, write: if request.auth != null;
  }
]
```

**上线推荐（按空间隔离）：**

```
agc.cloud.storage[
  match: /spaces/{spaceId}/{path=**} {
    allow read, write: if request.auth != null;
  }
  match: /users/{userId}/{path=**} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
]
```

> 规则语法以 AGC 控制台编辑器为准；改规则后 **保存并发布** 才生效。

**注意：**

- 必须已接入 **认证服务 + 华为账号登录**，`request.auth` 才有值
- 默认文件 **私有**，规则不匹配时上传成功但 TA 读不到

#### 15.3.4 检查 agconnect-services.json（Storage 段）

重新下载 json，确认有：

```json
"cloudstorage": {
  "default_storage": "xinyu-recipe",
  "storage_url": "https://..."
}
```

若缺少 `default_storage` → 手动补上，值为开通时的实例名 `xinyu-recipe`。

#### 15.3.5 客户端权限（HarmonyOS）

`module.json5` 已有 `INTERNET`；上传本地图片还需：

```json
"requestPermissions": [
  { "name": "ohos.permission.INTERNET" },
  {
    "name": "ohos.permission.READ_IMAGEVIDEO",
    "reason": "$string:perm_read_image",
    "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
  }
]
```

并在 `string.json` 增加 `perm_read_image` 说明文案。

上传流程（接代码时）：

```
选图 → 压缩 → cloudStorage.uploadFile(localPath, cloudPath)
     → 拿 downloadUrl → 写入 SpaceTask.checkInPhotoUrl
```

---

### 15.4 推荐操作顺序

```
1. 确认华为账号登录 OK
2. 云数据库 → 中国区域 → 存储区 RecipeSpace
3. 创建 7 个对象类型 + 权限 + 索引
4. 部署到 RecipeSpace
5. 导出 schema.json 到工程
6. 云存储 → 开通 xinyu-recipe → 配安全规则
7. 重新下载 agconnect-services.json 覆盖 rawfile
8. DevEco Sync + Run，看 Log 无 Permission Denied
```

---

### 15.5 检查清单

**云数据库：**

```
[ ] Cloud DB 区域：中国
[ ] 存储区 RecipeSpace 已创建并部署
[ ] 7 个对象类型已创建
[ ] 各对象权限已配置（Authenticated 可读写）
[ ] schema.json 已导出
[ ] agconnect-services.json 含 clouddb 段
```

**云存储：**

```
[ ] 实例名 xinyu-recipe 已开通
[ ] 数据处理位置：中国
[ ] 安全规则已保存发布
[ ] agconnect-services.json 含 cloudstorage.default_storage
```

---

### 15.6 常见报错

| 现象 | 原因 | 处理 |
|------|------|------|
| Permission Denied | 未登录 / 权限未开 Upsert | 先登录；Authenticated 开 Read+Upsert |
| zone 不存在 | 存储区未部署或名称不一致 | 确认 `RecipeSpace` 已部署 |
| schema 不一致 | 本地 json 与云端版本不同 | 重新导出 schema，版本号对齐 |
| Storage 找不到实例 | json 缺 default_storage | 补 `xinyu-recipe` 后重下 json |
| 上传 OK 下载 403 | 安全规则不允许读 | 调整 rules 或确认 request.auth |

---

### 15.7 相关官方文档

| 主题 | 链接 |
|------|------|
| 云数据库模型介绍 | https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-clouddb-aboutclouddb-0000001080975612 |
| 管理对象类型 | https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-clouddb-agcconsole-objecttypes-0000001127675459 |
| HarmonyOS 开发云数据库 | https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-clouddb-harmonyos-introduction-0000000000037728 |
| 开通云存储 | https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-cloudstorage-enable-service-0000001275330014 |
| 云存储安全规则 | https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-cloudstorage-security-rules-0000001050169411 |

配置完成后，可继续：**将 SpaceRepository / RecipeStatsRepository 改为 Cloud DB 读写，并接入打卡图上传**。

