# MacCalendar（日历）· macOS App 初版

一个使用 **SwiftUI + SwiftData** 编写的原生 macOS 日历应用（v1 初版）。

## 功能范围（v1）

- 月视图（6 行 × 7 列网格，跟随系统日历的每周起始日）与周视图切换
- 工具栏：今天、上一页 / 下一页（按月或按周）、新建事件
- 事件管理：新建、查看、编辑、删除（右键菜单 / 详情面板）
- 事件字段：标题、地点、起止时间、备注
- 校验：标题不能为空；结束时间必须晚于开始时间
- 右侧事件列表：按开始时间排序，支持按标题 / 地点 / 备注模糊搜索
- 本地持久化：SwiftData（`CalendarEvent` 模型，仅本机存储，不联网）
- 提醒：通过 `UNUserNotificationCenter` 发送本地用户通知，可选准时 / 提前 5、15、30 分钟 / 1 小时 / 1 天
- 点击日历中的某一天，会以该天上午 9:00 预填新建事件

### 明确不在 v1 范围内

iCloud / CloudKit 同步、与系统日历（EventKit）的双向同步、多日历账户管理、重复事件（RRULE）、协作者邀请、拖拽调整事件。这些建议作为后续迭代。

## 环境要求

- macOS 14.0 或更高版本（使用 SwiftData / iOS 17 时代 API）
- Xcode 15.4 或更高版本（Swift 5.10+）
- 工程为纯本地签名（Sign to Run Locally / Automatic），无需开发者账号即可在本机运行

## 构建与运行

### 用 Xcode（推荐）

1. 解压后双击打开 `MacCalendar/MacCalendar.xcodeproj`。
2. 顶部 Scheme 选择 **MacCalendar**，目标选择 **My Mac**。
3. 按 `⌘R` 运行；首次发送通知提醒时系统会弹出授权请求。

### 用命令行

```bash
cd MacCalendar
# 构建 Debug
xcodebuild -project MacCalendar.xcodeproj -scheme MacCalendar \
  -configuration Debug -destination 'platform=macOS' build

# 运行单元测试（逻辑层：日历网格数学、事件过滤/搜索、表单校验）
xcodebuild -project MacCalendar.xcodeproj -scheme MacCalendar \
  -destination 'platform=macOS' test
```

产物路径一般为：
`~/Library/Developer/Xcode/DerivedData/MacCalendar-*/Build/Products/Debug/MacCalendar.app`

## 单元测试说明

测试 target 为 `MacCalendarTests`，覆盖**纯逻辑层**（不依赖 UI 与数据库）：

- `CalendarMathTests`
  - 月视图网格固定 42 格、起点对齐每周首日（以 2026-10 / 2026-02 两个月份校验）
  - 周视图返回连续 7 天
  - 按天过滤事件：跨天事件、恰好在午夜结束的边界、开始时间排序
  - 搜索：标题 / 地点 / 备注、大小写不敏感、空白查询返回全部
  - 月份加减、同日 / 同月判断
- `EventValidatorTests`
  - 合法事件通过；空 / 纯空白标题拒绝；结束不晚于开始拒绝

测试使用固定的 `gregorian + UTC + en_US_POSIX + Sunday-first` 日历，确保在任何地区运行结果一致。

## 工程结构

```
MacCalendar/
├── MacCalendar.xcodeproj/            # Xcode 工程（含共享 Scheme）
├── MacCalendar/
│   ├── MacCalendarApp.swift          # App 入口、SwiftData 容器、设置场景
│   ├── Models/
│   │   └── CalendarEvent.swift       # SwiftData @Model
│   ├── Utilities/
│   │   ├── CalendarMath.swift        # 纯函数：网格/周/过滤/搜索（可测）
│   │   └── EventValidator.swift      # 表单校验（可测）
│   ├── Notifications/
│   │   └── NotificationController.swift  # UNUserNotificationCenter 封装
│   ├── Views/
│   │   ├── ContentView.swift         # 主窗口、工具栏、侧边栏、持久化接线
│   │   ├── CalendarViews.swift       # 月/周视图、星期表头、事件行
│   │   ├── EventEditorView.swift     # 新建/编辑表单 + EventDraft
│   │   ├── EventDetailView.swift     # 详情面板
│   │   └── SettingsView.swift        # 通知权限设置
│   ├── Assets.xcassets/
│   ├── Info.plist
│   └── MacCalendar.entitlements
└── MacCalendarTests/
    ├── CalendarMathTests.swift
    ├── EventValidatorTests.swift
    └── MacCalendarTests.entitlements
```

## 设计说明

- **可测试性**：日历计算全部集中在 `CalendarMath`，通过 `CalendarEventProtocol`
  协议解耦 SwiftData 模型，单元测试用轻量结构体构造事件，不触碰数据库。
- **沙盒**：App 启用 App Sandbox，仅声明只读的用户选择文件权限；数据通过
  SwiftData 存放在容器的 Application Support 中。
- **本地化**：开发区域为简体中文，所有界面文案使用 `String(localized:)`，
  后续可直接导出 String Catalog 做英文等本地化。
- **通知标识**：每条事件的通知请求 ID 为
  `maccalendar.event-reminder.<UUID>`，编辑时先取消旧请求再重新排程。

## 2FA 验证码生成工具（TwoFactorAuth / `totp`）

仓库同时包含一个跨平台的 Swift Package：一个 TOTP/HOTP 算法库和一个 `totp`
命令行工具，用于生成 Google Authenticator 等应用兼容的两步验证码。

- 标准：RFC 4226（HOTP）、RFC 6238（TOTP）、RFC 4648 Base32
- 支持 SHA1 / SHA256 / SHA512、6–8 位数字、自定义时间步长
- 支持直接传入 Base32 密钥，或解析 `otpauth://totp/...` 配置 URI
  （密钥、issuer、digits、period、algorithm 均从 URI 读取）
- 加密原语使用 [apple/swift-crypto](https://github.com/apple/swift-crypto)，
  在 Linux 与 macOS 上均可构建（macOS 平台要求 macOS 12+）

### 构建与测试

```bash
swift build
swift test
```

测试使用 RFC 4226 / RFC 6238 官方测试向量和 RFC 4648 Base32 向量，
并覆盖 `otpauth://` URI 解析的正常与错误路径。

### 使用示例

```bash
# 用 Base32 共享密钥生成当前验证码
swift run totp --secret JBSWY3DPEHPK3PXP

# 解析二维码里的 otpauth 配置 URI
swift run totp -u "otpauth://totp/ACME:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME"

# 固定时间 / 算法 / 位数（便于核对）
swift run totp -s GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ -t 59 -d 8
# 94287082

# 持续运行，每个时间步打印新验证码
swift run totp -s JBSWY3DPEHPK3PXP --follow
```

退出码：成功为 0；参数或密钥错误为 2（错误信息输出到 stderr）。

## 已知限制（交付时未在 macOS 上验证）

本工程由 Linux 环境生成，**未经过 Xcode 编译与 UI 运行验证**。已完成的静态自检
（JSON / plist 合法性、pbxproj 引用一致性）见随附实施说明；请在 macOS + Xcode
上执行上述 `xcodebuild test` 与 `⌘R` 运行确认。如首次打开 Xcode 提示
“Resolve Package / Validate Settings”，直接采用默认值即可（工程无第三方包依赖）。
