# 架构与工程配置

## 工程
- Xcode 工程名：LevelTales；Bundle ID 占位：`app.leveltales`（提审前替换）；Deployment Target：iOS 26.0。
- 单 App target + 一个 UnitTest target。无扩展、无 Widget（v1）。
- SPM 依赖：无。

## 目录结构（按此建，不要自创层级）
```
LevelTales/
  App/            LevelTalesApp.swift, AppState.swift(全局状态: 家长会话/购买状态)
  Models/         见 models.md（SwiftData @Model + 种子数据 Codable 结构）
  Seed/           seed/*.json 复制进 bundle 的副本 + SeedImporter.swift
  Services/       GenerationService, ValidationService, SpeechService(TTS),
                  ReadAloudService(SpeechAnalyzer), QuizService,
                  ReviewScheduler, StoreService, StatsService
  Features/
    Onboarding/   P01 欢迎, P15 不支持机型
    ParentGate/   P02 家长门
    Placement/    P03 定级
    Home/         P04 孩子端首页
    Story/        P05 主题, P06 等待, P07 阅读, P08 跟读, P09 理解题, P10 完成
    Parent/       P11 报告, P12 生词本, P13 付费墙, P14 设置
  Components/     大按钮、词卡、释义弹窗等复用组件
  Resources/      默认插图 L1-L6 各 1 张（占位图即可）、主题图标
```

## 权限与 Info 配置
- `NSMicrophoneUsageDescription`："用来听孩子跟读故事，只在这台设备上处理，不会上传。"
- `NSSpeechRecognitionUsageDescription`：同上口径。
- 无需联网权限声明；不申请 IDFA、不申请通知（v1 无推送）。
- App Privacy（提审填报）：Data Not Collected。

## 全局状态（AppState，@Observable）
- `parentSessionExpiresAt: Date?`（内存）— 家长门会话，规则见 PRD M1。
- `isUnlocked: Bool` — 由 StoreService 同步。
- `modelAvailability` — 启动时检测 `SystemLanguageModel.default.availability` 与 SpeechAnalyzer 可用性，结果注入各 Service。

## 数据流总则
- View 只调 Service 与 AppState，不直接写 SwiftData（写入收敛到 Services/Repositories 层：ChildRepository、StoryRepository、WordRepository 用 ModelContext 封装）。
- 生成链路：StoryView → GenerationService → (ValidationService 校验) → StoryRepository 落库 → 返回 Story 供阅读。
- 全部 Service 写成 protocol + 实现类，方便单测注入假实现（尤其 GenerationService 的模型调用要可替换：单测用 StubModel 返回预设文本）。

## 错误处理总则
- 孩子端永不弹错误框：任何失败走降级（模板故事/鼓励反馈/默认图）。
- 家长端错误用一行文案提示（如购买失败"购买没有完成，请再试一次"）。
- 所有降级事件记入 StatsService 本地计数（degraded 事件带 reason）。
