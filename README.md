# LevelTales

少儿英语分级阅读生成 App（iOS）：按孩子的级别（L1–L6，对齐 CEFR / 剑桥 YLE）用端侧大模型现场生成受控词汇的英语故事，带朗读、跟读比对、理解题和生词复习；家长一次买断，无订阅。全部生成与数据处理在设备本地完成，无账号、不收集儿童数据。

## 仓库说明

本仓库包含产品 PRD、实现规格、起始种子数据和 iOS 启动工程。当前原型根据 Apple Intelligence 可用性进入欢迎页或不支持说明页。编码按 `AGENTS.md` 的指引进行。

| 路径 | 内容 |
|---|---|
| `PRD.md` | 完整产品 PRD 与功能清单（交付范围 = §6 功能清单总表） |
| `docs/architecture.md` | 工程结构、模块划分、权限与工程配置 |
| `docs/models.md` | 数据模型的 Swift 代码级定义 |
| `docs/screens.md` | 15 个页面逐页实现规格 |
| `docs/services.md` | 服务层接口签名与实现逻辑 |
| `docs/prompts-and-algorithms.md` | 提示词模板 T1–T3 与算法 A1–A3（含测试向量） |
| `docs/build-steps-and-tests.md` | 12 步实现顺序、每步验收与单元测试清单 |
| `seed/*.json` | 种子数据起始集：词表（L1 全量 150 词 + L2 部分 60 词）、六级句型、定级题、模板故事、黑名单/同义词/主题等 |
| `LevelTales.xcodeproj` | iOS App、单元测试 target 和共享方案 |

## 运行启动原型

### 在 Mac 上准备软件

1. 安装带 iOS 26 SDK 的 Xcode 26 或更新版本，首次打开时完成组件安装。各 Xcode 版本支持的 macOS 版本见 [Apple Xcode 系统要求](https://developer.apple.com/support/xcode/)。
2. 在 **Xcode → Settings → Components** 安装 iOS 26 或更新版本的 iOS Simulator 运行时。Xcode 提供 Swift 编译器和测试工具，工程无需安装第三方包或插件。

### 在模拟器切换两个启动页

1. 用 Git 克隆仓库并切换到含启动原型的分支，已有检出可直接打开该分支下的工程。

   ```bash
   git clone --branch codex/leveltales-ios-bootstrap https://github.com/zakeXu1106/LevelTales.git
   cd LevelTales
   open LevelTales.xcodeproj
   ```

2. 在 Xcode 顶部选择 `LevelTales` 方案和一台 iOS 26 或更新版本的 iPhone 模拟器。模拟器运行无需设置签名团队。
3. 打开 **Product → Scheme → Edit Scheme → Run → Arguments**，在 **Arguments Passed On Launch** 中启用 `--model-available`，按 `⌘R` 查看 P01 欢迎页。
4. 停止 App，关闭上一个参数，改为启用 `--model-unavailable`，再按 `⌘R` 查看 P15 设备说明页。按 `⌘U` 运行默认 Debug 单元测试。

后续更新时，在同一分支执行 `git pull --ff-only`，再按 `⌘R` 重新运行。当前原型可查看 P01 和 P15，定级和手动选级入口将在对应开发步骤接入。

### 在 iPhone 上验证系统能力

1. 使用 iOS 26 或更新版本的 iPhone。P01 的真实能力路径需要支持 Apple Intelligence 的机型，并在 **设置 → Apple Intelligence 与 Siri** 启用且等待模型就绪。
2. 将 iPhone 连接到 Mac，在 Xcode 登录 Apple 账户，并在 App target 的 **Signing & Capabilities** 选择团队。按设备提示信任 Mac 并启用开发者模式。如果占位 Bundle ID `app.leveltales` 无法注册，在自己的检出中换成唯一 Bundle ID。
3. 在 **Edit Scheme → Run → Arguments** 关闭两个模拟参数，选中这台 iPhone 并按 `⌘R`。模型可用时进入 P01，模型不可用时进入 P15。可从 P15 切到系统设置，完成启用并等模型就绪后返回 App，检查是否进入 P01。

## 技术栈

Swift 6 · SwiftUI · SwiftData · Foundation Models（端侧生成 + PCC 兜底）· SpeechAnalyzer · StoreKit 2 · iOS 26+（Apple Intelligence 机型）· 零第三方依赖 · 零网络（PCC 除外）
