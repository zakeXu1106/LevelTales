# 分步实现与测试

按顺序实现，每步的验收通过后再进下一步。步 1–3 是地基，不要并行跳步。

## 步骤
1. **工程脚手架**：按 architecture.md 建工程与目录；P15 能力检测与 P01 欢迎页骨架。验收：非支持机型（模拟器关 Apple Intelligence 不可得时以开关模拟）显示 P15；支持路径进 P01。
2. **种子导入 + Lexicon**：SeedImporter 读 seed/*.json 建内存索引与 SwiftData 初始数据；幂等（seedVersion）。验收：单测断言 L1 池大小 = 150、lemmaByForm 含 "dogs→dog" 类映射（按数据实际）。
3. **ValidationService + A1 单测**：先写服务与 V1–V4 测试向量，全过。
4. **家长门 + 档案**：P02（含会话规则）、建档、P14 设置（小名/改级/语速/时长上限的存取）。验收：PRD T-02/T-03 路径手动走通。
5. **定级**：P03 答题引擎与结果页（用 placement.json 示例题）。验收：T-04/T-05（全对/全错模拟）定级符合预期。
6. **生成管线**：TextModel 生产实现（端侧 session）+ GenerationPipeline（A1 编排 + 模板兜底）+ P05/P06。验收：真机生成一篇 L1 故事并落库；断网+Stub 抛错时交付模板故事。
7. **阅读器**：P07（分页/TTS 高亮/点词释义）+ P04 首页（继续读/徽章/额度与时长拦截）。验收：T-11/T-12 手动走通。
8. **跟读**：ReadAloudService + P08 + A3 单测（C1–C3）。验收：T-13/T-14/T-16 手动走通（真机）。
9. **理解题 + 生词**：QuizService（T2+校验+兜底）+ P09/P10 + ReviewScheduler（A2 单测向量）。验收：T-19/T-20、A2 向量全过。
10. **家长端**：P11 报告（含周报 T3、晋升、屏蔽）、P12 生词本。验收：T-24、屏蔽后同模板不再出现。
11. **付费**：StoreService + P13 + 额度计数接线。验收：沙盒 T-21/T-22/T-23。
12. **统计与收尾**：StatsService 接线、P14 统计区、PRD §12 的 P0 用例全量回归、合规自查（T-28）。

## 单元测试清单（必须实现且全绿）
- ValidationService：A1 向量 V1–V4 + 空文本 + 全大写/标点混杂归一化。
- ReviewScheduler：A2 向量（quota 与到期词组合 3 种）+ 掌握判定边界（2 篇不触发、3 篇+答对触发、3 篇未答对不触发）。
- ReadAloud：A3 向量 C1–C3 + 空转写（flagged 返回全词但仍受 prefix(3) 限制——注：空转写且 conf 低走 encouragementOnly，二者不冲突时按 conf 优先）。
- PlacementEngine：全对→高级别、全错→L1、提前结束条件（连续 3 同级全对）。
- QuotaManager：同日第 2 次拦截、跨日重置、模板兜底不扣减、已解锁不拦截。
- SeedImporter：重复导入不重复建数据；JSON 缺字段时抛错且不写半成品。

## 真机验证标注
涉及 Foundation Models / SpeechAnalyzer / ImagePlayground 的用例只能在 Apple Intelligence 真机验证；模拟器阶段用 Stub 跑通流程并在代码留 `// TODO(real-device)` 标记，步 12 前清除或转为已验证记录。
