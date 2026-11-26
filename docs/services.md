# 服务层实现规格（接口 + 关键逻辑）

## GenerationService（故事生成，协议隔离模型调用）
```swift
protocol TextModel {   // 生产实现包 LanguageModelSession；单测用 Stub
    func generateStory(prompt: StoryPrompt) async throws -> StoryDraft
    func generateQuiz(story: String, targetWord: String, targetZh: String) async throws -> QuizSet
    func generateWeeklySummary(stats: WeeklyStats) async throws -> String
}
struct StoryPrompt {           // 由 T1 模板组装，见 prompts-and-algorithms.md
    let themeName: String; let heroName: String
    let minWords: Int; let maxWords: Int; let paragraphCount: Int
    let newWords: [String]; let allowedWords: [String]
    let allowedPatterns: [String]; let maxSentenceWords: Int
}
```
- 生产实现：`LanguageModelSession(instructions:)` + `respond(to:generating:)` 返回 @Generable 结构（定义见 prompts 文档）。
- 端侧不可用/抛错 → 用 PCC 配置的 session 重试 1 次 → 再抛错给管线走模板兜底（管线顺序见算法 A1，**重试编排在 GenerationPipeline，不在 Service 内**）。
- GenerationPipeline.generate(level, theme) 步骤：组装参数（ReviewScheduler.pickNewWords 取词）→ 循环 A1 → 成功落库 Story（source=.model）→ 兜底取 TemplateStory 落库（source=.template）→ 生成插图（异步，不阻塞返回；失败 illustrationName=nil）。
- 插图：`ImageCreator` 以 "children's picture book illustration, {{theme}}, a small friendly animal hero, soft colors, no text" 生成；超时 8 秒放弃。

## ValidationService（纯函数，无状态，必须可单测）
```swift
struct ValidationResult { let passed: Bool; let violationRate: Double; let violations: [String]; let unsafe: Bool; let missingNewWords: [String] }
func validate(text: String, level: Int, expectedNewWords: [String], lexicon: Lexicon,
              blacklist: Set<String>, synonyms: [String:String],
              properNouns: Set<String>) -> ValidationResult
func applyingSynonyms(text: String, violations: [String], synonyms: [String:String]) -> String?
```
逻辑严格按算法 A1：归一化（小写/去标点/缩略展开）→ form→lemma → 超纲判定 → 黑名单（对 lemma 与原文小写各查一遍）→ 新词出现次数（按 form 出现计次，lemma 任一 form 出现即计）。

## SpeechService（TTS）
- 封装 AVSpeechSynthesizer：`speak(sentences:[String], rate:)` 逐句队列；delegate 回调驱动当前句高亮（发布 currentSentenceIndex）。
- rate 映射：slow=0.42，normal=0.5；voice 固定 `en-US` 高质量语音（取 available 里 enhanced/premium 优先）。
- `speakWord(_:)` 供点词发音与跟读标词点听。

## ReadAloudService（跟读，SpeechAnalyzer）
- 流程：请求麦克风+语音识别权限（首次在 P08 触发，拒绝则整模块降级为"自己读一遍"模式并记 degraded）→ 每句一个录音会话：`SpeechAnalyzer` + `SpeechTranscriber(locale: en-US)` 流式取结果 → 结束取 final transcript 与平均置信度 → 调 A3 比对 → 返回 Feedback。
- 音频缓冲只在内存（AnalyzerInput 不落盘）；会话结束释放全部引用。**禁止把音频写入文件**；如框架需要临时文件，用 tmp 目录且在 defer 中删除，并加单测校验目录无残留。
- Feedback 枚举：`.flagged([String])` / `.encouragementOnly`。

## QuizService
- generate：调 TextModel.generateQuiz → 逐题校验（evidence 逐字 ∈ 正文；options 4 个互不相同；correctIndex 合法；wordMeaning 题的正确选项 == 词条 zh）→ 不合格题用同级同主题 D6 兜底题替换（兜底题从 TemplateStory.quiz 或 quiz_fallback 数据取）→ 组装 3 题返回。
- 结果回写：wordMeaning 题对错 → WordRepository.addQuizResult(lemma:, correct:)。

## ReviewScheduler（A2 实现）
- `pickNewWords(level:quota:today:) -> [String]` 与 `recordStoryDelivered(story:)`、`checkMastery(record:)` 按 A2 伪代码逐行实现；间隔数组 `[1, 3, 7]`，stage 超界取 7。

## StoreService（StoreKit 2）
- 启动：`Product.products(for: ["leveltales.fullaccess"])` 拉产品；`Transaction.currentEntitlements` 同步解锁态；后台任务监听 `Transaction.updates`。
- `purchase()` → 成功后 `transaction.finish()` 并置解锁；`restore()` → `AppStore.sync()` 后重查权益。
- UI 价格一律 `product.displayPrice`。

## StatsService（M11）
- `bump(_ event: String, by: Int = 1)` 写 Prefs.stats；事件名用 PRD M11 清单 + `degraded_<reason>`。
