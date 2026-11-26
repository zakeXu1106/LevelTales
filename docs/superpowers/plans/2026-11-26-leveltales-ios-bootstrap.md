# LevelTales iOS 工程与启动实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**目标**　建立可由 Xcode 打开的 App 和单元测试工程，实现 P01 欢迎页与 P15 不支持说明页的启动分流。

**架构**　`LevelTalesApp` 从系统读取 Foundation Models 可用性，通过纯 Swift 的 `LaunchRoute` 解析启动目的地。Debug 启动参数允许在模拟器覆盖系统检查，Release 始终读取真实能力。启动页为独立 SwiftUI 视图。

**技术栈**　iOS 26 SDK、Swift 6、SwiftUI、Foundation Models、XCTest。

**设计**　[LevelTales MVP](../specs/2026-11-26-leveltales-mvp-design.md) 第 3 节和第 7 节第 1 步。后续阶段在通过此步验收后按已确认的顺序执行。

## 全局约束

- iOS 部署目标 26.0，Swift 语言模式 6.0，Bundle ID 暂用 `app.leveltales`。
- 工程使用 `LevelTales.xcodeproj`，只有一个 App target 和一个 UnitTest target，无第三方包。
- P15 没有后续流程入口。定级与家长门交互在对应步骤实现，此步仅提供 P01 欢迎页。
- 现有任务已在独立的 `work` 分支云检出中，直接在该检出工作。
- Apple SDK 构建和模拟器走查属于第 1 步验收。Linux 可验证框架无关的路由，另做 Swift 语法和工程引用检查。

## 文件分配

| 路径 | 责任 |
| --- | --- |
| `LevelTales.xcodeproj/project.pbxproj`、`LevelTales.xcodeproj/xcshareddata/xcschemes/LevelTales.xcscheme` | 两个 target、编译配置和共享运行与测试方案 |
| `LevelTales/App/LaunchRoute.swift` | 按能力及 Debug 参数返回 P01 或 P15 |
| `LevelTales/App/LevelTalesApp.swift` | 包装真实的系统能力检查、挂载目的页面 |
| `LevelTales/Features/Onboarding/WelcomeView.swift` | P01 价值与隐私说明 |
| `LevelTales/Features/Onboarding/UnsupportedDeviceView.swift` | P15 设备与系统能力说明 |
| `LevelTalesTests/LaunchRouteTests.swift` | 真实路由断言，替换系统可用性输入 |
| `README.md` | 从 Xcode 运行、切换模拟器分支与验收方式 |

## 评审重点

- 系统支持和不支持时分别选择正确首页，校验后者没有继续入口。
- Debug 覆盖能在真实能力为相反值时跑通。
- 两个互斥 Debug 参数同时传入时恢复系统判定。
- Release 中两个覆盖参数均无效。
- 长文本和辅助功能大字号仍可浏览两个启动页。

## 任务 1　原生启动骨架

- [x] 先添加 `LaunchRouteTests`。断言真实能力为 true 时 `.welcome`、false 时 `.unsupported`。分别传入 `--model-available`、`--model-unavailable` 和相反的系统值，断言 Debug 强制选路且 Release 保留系统结果。两个参数一同传入应保留系统结果。
- [x] 运行 XCTest。Linux 用临时 Swift Package 加载测试文件和同名纯 Swift 产品模块，待实现的 `resolve(arguments:systemIsAvailable:)` 返回错误路由时测试应失败。
- [x] 在 `LaunchRoute.swift` 实现 `enum LaunchRoute: Equatable` 和 `static func resolve(arguments: [String], systemIsAvailable: () -> Bool) -> Self`。Debug 仅识别上述完整参数，仅一个覆盖参数生效时无需读取系统值。
- [x] 建立共享 scheme 和两个 Xcode target，在 `LevelTalesApp` 把 `SystemLanguageModel.default.availability` 的 `.available` 映射为 true，其余映射为 false。分别挂载可滚动的 P01 与 P15。P01 展示品牌、分级阅读和本地隐私说明，P15 说明需要支持 Apple Intelligence 的 iPhone。
- [x] 运行路由测试 Debug 和 Release，期望各 5 项通过。检查工程文件、scheme 的 target 与源码引用，并用 Swift 前端解析 SwiftUI 和测试文件。补齐 README 启动说明。
- [ ] 在 macOS 的 Xcode 中选择 iOS 26+ 模拟器，运行 `xcodebuild test -project LevelTales.xcodeproj -scheme LevelTales -destination 'platform=iOS Simulator,id=<模拟器 UUID>'`，期望 `TEST SUCCEEDED`。分别使用两种覆盖参数启动，检查 P01、P15 的页面内容、无继续入口和大字号滚动。用支持设备确认真实能力判定。
- [x] 提交已验证的工作，保留尚未运行的 Apple SDK 验收记录。

## 验证记录

- Swift 6.2.3 Linux，测试先对未实现路由运行，5 项中 3 项按预期失败。
- 接入实际路由后，Debug 和 Release 各运行 5 项，均通过。Swift 源码语法解析、工程和共享方案的 target、源码与配置检查通过。
- 当前云主机运行 Linux，macOS/Xcode 构建、iOS 模拟器页面走查和实际设备能力验证待完成。
