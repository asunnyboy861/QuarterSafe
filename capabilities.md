# QuarterSafe — 配置文档

生成时间：2026-09-15

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**。不配置这些项，App 仍可正常使用所有核心功能（截止日倒计时、通知链、30% 简易计算、记账、缴费台账、基础锁屏小组件全部可用）。配置后可获得完整体验（Safe Harbor 精算、PDF 导出、小组件罐子进度等 Pro 功能的购买闭环）。

### 🔵 IAP StoreKit 配置（必须 — Pro 买断购买闭环）

**影响功能**：不创建 IAP 产品，付费墙会显示 "Purchase unavailable"，用户无法完成 $19.99 Pro 买断购买。免费层功能不受影响。

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → **QuarterSafe**（先创建 App 记录，Bundle ID 选择 `com.zzoutuo.QuarterSafe`）
2. 左侧菜单 → **Features**（功能）→ **In-App Purchases**（App 内购买项目）
3. 点击 **"+"** → 选择 **Non-Consumable（非消耗型）**
4. 按以下信息填写：

| 字段 | 值 |
|------|-----|
| Reference Name | `QuarterSafe Pro Lifetime` |
| Product ID | `com.zzoutuo.quartersafe.lifetime` |
| Price | $19.99（Tier 20） |
| Display Name (en-US) | `QuarterSafe Lifetime`（≤35 字符） |
| Description (en-US) | `One-time purchase. All Pro features, forever.`（≤55 字符） |

5. 截图审核所需内容可留空，保存后状态为 "Ready to Submit"
6. ⚠️ 创建后需等待 Apple 处理（通常几分钟到 1-2 小时）
7. 本地测试：Xcode 中已可通过 Sandbox 测试；上架后用 **Settings → Restore Purchases** 验证

### 🟡 App Group 注册（增强 — 小组件罐子进度）

**增强功能**：锁屏/桌面小组件显示罐子进度百分比与应缴金额
**不配置的影响**：小组件仍显示截止日倒计时（由打包的税表独立计算），仅罐子进度部分隐藏
**当前状态**：App 与 Widget target 的 entitlements 文件已包含 App Group 声明，模拟器构建正常

**如需启用完整小组件，请手动配置**：
1. 打开 [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**
2. 右上角 **"+"** → 选 **App Groups** → 填写 `group.com.zzoutuo.QuarterSafe` → 注册
3. 回到 **Identifiers** → 找到 `com.zzoutuo.QuarterSafe` → 编辑 → 勾选 **App Groups** → 关联上面创建的组
4. 同样为 `com.zzoutuo.QuarterSafe.Widget` 勾选并关联该 App Group
5. ⚠️ 配置完成后在 Xcode 重新构建（自动签名会重新生成描述文件）

### 🟢 App Store Connect 审核信息配置

**影响功能**：不配置可能延长审核时间

**配置步骤**：
1. App Store Connect → App → **App Review Information**
2. **Notes** 字段粘贴 `keytext.md` 末尾 "## Review Notes" 部分的内容（含买断产品信息、隐私说明、免责声明位置）
3. **Privacy Policy URL**: `https://asunnyboy861.github.io/QuarterSafe/privacy.html`
4. **Support URL**: `https://asunnyboy861.github.io/QuarterSafe/support.html`
5. **Marketing URL**: `https://asunnyboy861.github.io/QuarterSafe/`

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| Local Notifications | UNUserNotificationCenter 本地通知链，无需 entitlement | ✅ 已配置 |
| In-App Purchase | StoreKit 2 代码已集成，无需 entitlement 文件 | ✅ 已配置 |
| App Groups entitlements | App 与 Widget 的 .entitlements 文件已创建（后台注册见上方手动步骤） | ✅ 已配置 |
| Outgoing Network Connections | 联系客服 HTTPS 出站，iOS 默认允许 | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers：`https://feedback-board.iocompile67692.workers.dev/api/feedback` | ✅ 已部署并硬编码 |
| GitHub Pages | Landing/Support/Privacy 三页已上线 | ✅ 已部署 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | 4 引擎（Deadline/Tax/Jar/Proof）纯函数 + 22 单元测试全通过 | ✅ 已完成 |
| SwiftData 模型 | IncomeEvent/ExpenseEvent/Payment/Profile，事件溯源重算 | ✅ 已完成 |
| ContactSupportView | 7 主题磁贴、必填校验、后端对接、成功/失败反馈 | ✅ 已完成 |
| SettingsView | 免责声明、税表版本、政策链接、客服入口、版本号动态读取 | ✅ 已完成 |
| PurchaseManager | StoreKit 2 买断 + Transaction.currentEntitlement + 事务监听 | ✅ 已完成 |
| Widget target | QuarterSafeWidget 锁屏(圆形/矩形/行内)+桌面(小/中)，独立计算截止日 | ✅ 已完成 |
| QA 迭代 | improvement_plan_1.md，1 轮迭代，全部退出标准达成 | ✅ 已完成 |
| App 图标 | Agnes 生成 1024×1024（RGB 无 alpha），已配置深色/着色变体 | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/QuarterSafe | ✅ 已推送 |
| GitHub Pages | https://asunnyboy861.github.io/QuarterSafe/ | ✅ 已启用 (built) |
| App Store 元数据 | keytext.md 已生成并全部验证通过（subtitle 25 字符、keywords 100 字符内、ASCII 纯净） | ✅ 已完成 |
| 定价配置 | price.md（免费 + $19.99 非消耗型买断） | ✅ 已完成 |

### 💡 使用提示（非开发者配置，App 内操作即可）

- 税表年份更新：每年 10 月用 IRS/SSA 公告核对 `TaxYearConfig-2027.json`（配置驱动，代码零修改）。
- 首发早鸟价 $12.99：只需在 App Store Connect 调价，无需改代码。

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据（已重组，保留检测依据）。

### Analysis

- "通知链 D-21/14/7/1/0" → UserNotifications（本地通知，无推送）
- "锁屏小组件 + 灵动岛" → WidgetKit（已实现）；灵动岛 Live Activity 未实现，相关文案已从付费墙/落地页/元数据移除
- "买断 $19.99" → StoreKit 2 非消耗型 IAP
- "可选拍照凭证" → PhotosPicker（iOS 隐私安全的进程外选择器，无需相机/相册权限字符串）
- "可选 iCloud 私有库同步" → 未启用（本地 SwiftData 已完整覆盖核心场景）
- "无网络请求、无 SDK" → 唯一网络请求 = 联系客服反馈 POST；隐私标签 Data Not Collected
- "SFSafariViewController 跳转 IRS Direct Pay" → 外链打开，无支付代码

### No Configuration Needed

- 推送通知（仅本地通知）、定位、HealthKit、Siri、Sign in with Apple、后台模式（前台重算 + 小组件 timeline 刷新）

### Verification

- iPhone 16 (iOS 26.4) 构建+运行：✅
- iPad Pro 13-inch (M5) 构建+运行：✅
- 引擎单元测试 22/22 通过（含 2026 Q2 工作日规则、假日顺延、Safe Harbor 三规则、小额豁免、结转）
