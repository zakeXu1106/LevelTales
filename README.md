# LevelTales

少儿英语分级阅读生成 App（iOS）：按孩子的级别（L1–L6，对齐 CEFR / 剑桥 YLE）用端侧大模型现场生成受控词汇的英语故事，带朗读、跟读比对、理解题和生词复习；家长一次买断，无订阅。全部生成与数据处理在设备本地完成，无账号、不收集儿童数据。

## 仓库说明

本仓库目前是**开发启动包**（尚无代码）：产品 PRD、实现规格文档与可运行的起始种子数据。编码按 `AGENTS.md` 的指引进行。

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

## 技术栈

Swift 6 · SwiftUI · SwiftData · Foundation Models（端侧生成 + PCC 兜底）· SpeechAnalyzer · StoreKit 2 · iOS 26+（Apple Intelligence 机型）· 零第三方依赖 · 零网络（PCC 除外）
