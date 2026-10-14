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

### 在 Linux 上运行同一套逻辑测试（无需 Xcode）

仓库根目录的 `Package.swift` 是一个仅编译纯逻辑层的 SwiftPM 切片
（只包含 `MacCalendar/Utilities` 与 `MacCalendarTests/`，不含 SwiftUI/SwiftData），
源文件与 Xcode 测试 target 完全相同：

```bash
# 需要 Swift 5.9+（已在 Ubuntu 24.04 + Swift 6.0.3 验证）
swift test
```

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

## 已知限制

- 纯逻辑层（`MacCalendar/Utilities`）与全部 12 个逻辑单元测试**已在 Linux
  Swift 6.0.3 实际编译并运行通过**（`swift test`，12/12 passed）。
- SwiftUI 界面、SwiftData 持久化与本地通知**尚未在 macOS/Xcode 做编译与
  UI 运行验证**。请在 macOS + Xcode 上执行上述 `xcodebuild test` 与 `⌘R`
  运行确认。如首次打开 Xcode 提示 “Resolve Package / Validate Settings”，
  直接采用默认值即可（工程无第三方包依赖）。
