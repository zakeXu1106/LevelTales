# AGENTS.md — LevelTales 编码指引

你将据此仓库实现 iOS App「LevelTales」MVP v1.0。先完整阅读本文件，再按顺序读 `PRD.md` 与 `docs/` 下全部文档，然后按 `docs/build-steps-and-tests.md` 的步骤顺序实现，每步完成后跑该步的验收项，不要跳步。

## 文档地图
| 文件 | 内容 |
|---|---|
| `PRD.md` | 完整产品 PRD 与功能清单（需求口径以它为准；与 docs 冲突时，产品规则以 PRD 为准、实现细节以 docs 为准） |
| `docs/architecture.md` | 工程结构、模块划分、依赖、权限与工程配置 |
| `docs/models.md` | 全部数据模型的 Swift 代码级定义（可直接粘贴） |
| `docs/screens.md` | 逐页面实现规格：布局、状态、交互、导航 |
| `docs/services.md` | 全部服务的接口签名与实现逻辑 |
| `docs/prompts-and-algorithms.md` | 提示词模板 T1–T3、算法 A1–A3（含测试向量） |
| `docs/build-steps-and-tests.md` | 分步实现任务 + 每步验收 + 单元测试用例 |
| `seed/*.json` | 真实种子数据（见下方说明） |

## 硬性约束（违反任何一条即实现错误）
1. iOS 26.0+，Swift 6，SwiftUI + SwiftData；仅 Apple Intelligence 机型可用核心功能。
2. 零网络：除 Foundation Models 框架的 PCC 兜底外，不得有任何网络请求；不得集成任何第三方 SDK/依赖（SPM 依赖数 = 0）。
3. 儿童录音只进内存/临时目录，比对后立即删除，禁止写入 SwiftData 或 Documents。
4. 孩子端界面不得出现价格、购买按钮、设置入口；购买只能发生在家长门之后。
5. 价格字符串只能来自 StoreKit `Product.displayPrice`，禁止硬编码金额。
6. 生成内容必须过 A1 校验管线才能展示给孩子，无例外路径。

## 种子数据现状（重要）
`seed/` 提供的是**可运行的起始数据集**，不是最终全量数据：
- `words.json`：L1 全量（150 词）+ L2 部分（60 词）；其余级别按 PRD §8.3 由内容工作补齐——代码必须按格式通用处理任意级别数据，不得针对 L1/L2 写死逻辑。
- `patterns.json`：L1–L6 全量句型。
- `placement.json`：L1/L2 示例题（每级 6 题，正式版每级 ≥20 题，格式即最终格式）。
- `template_stories.json`：L1×2、L2×2，含理解题（正式版每级 ≥10 篇）。
- `synonyms.json` / `blacklist.json` / `contractions.json` / `proper_nouns.json` / `themes.json`：起始版，格式即最终格式。
App 首启把 `seed/*.json` 导入 SwiftData/内存索引；导入逻辑写成幂等（seedVersion 相同则跳过）。

## 完成定义
build-steps 全部步骤验收通过 + `docs/build-steps-and-tests.md` 中全部单元测试用例通过 + PRD §12 的 P0 用例已走通（需 Apple Intelligence 真机的用例在模拟器不可测时，代码须有明确降级路径并标注 `// TODO(real-device)`）。
