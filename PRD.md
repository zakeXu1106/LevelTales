# LevelTales · MVP 完整落地 PRD 与功能清单

| 项 | 内容 |
|---|---|
| 文档版本 | v1.0（2026-11-26） |
| 用途 | **开发交付文档**：供编码方（工程师或编码模型）直接据此实现 MVP v1.0。功能细化到功能点级，每点含规则、边界与验收 |
| 产品 | LevelTales — 少儿英语分级阅读生成 App（iOS） |
| 上位文档 | 《少儿英语分级阅读App-PRD-MVP》（定位/商业模式以其为准，本文与其冲突时以本文的功能规格为准） |
| 状态 | 付费意愿验证进行中；定价与买断形态如验证结论有变，只需改 §3.4 与 M9，不影响其余规格 |

---

## 1. 技术约束（编码前必读，全部为硬性）

| 项 | 约定 |
|---|---|
| 平台 | iOS 26.0+，仅 Apple Intelligence 机型（iPhone 15 Pro 及以上）；不支持的机型在启动时显示说明页并退出流程 |
| 语言/框架 | Swift 6 + SwiftUI + SwiftData；并发用 Swift Concurrency |
| 生成 | Foundation Models 框架：`SystemLanguageModel` + `LanguageModelSession`；结构化输出用 `@Generable` / `@Guide`；端侧不可用或连续失败时走 PCC 配置（同框架云端模型），再失败走模板兜底（见 A1 管线） |
| 语音转写 | Speech 框架 iOS 26 `SpeechAnalyzer` + `SpeechTranscriber`（locale: en-US），全程本地 |
| 朗读 | `AVSpeechSynthesizer`，en-US 语音 |
| 插图 | ImagePlayground 框架 `ImageCreator`，style 固定 `.illustration` |
| 购买 | StoreKit 2，非消耗型内购 1 个：产品 ID 暂定 `leveltales.fullaccess`（Bundle ID 定版时统一替换） |
| 网络 | **除 PCC 兜底外零网络请求**；不集成任何第三方 SDK（无分析、无广告、无崩溃上报第三方服务） |
| 存储 | 全部数据本地 SwiftData + 少量 UserDefaults（设置与额度计数）；无账号、无服务器 |
| 种子数据 | 随包 JSON（见 §7），App 首启时导入 SwiftData；种子数据版本字段 `seedVersion`，为后续升级预留 |

## 2. 名词定义（全篇统一口径）

- **级别**：L1–L6，规格见 §4 分级表。
- **词汇池（vocabPool）**：某级及以下全部允许出现的词集合。词条结构见 §6 D2。
- **新词（newWord）**：本篇故事刻意引入的、属于当前级别词汇池但孩子尚未掌握的词，每篇 2–6 个（按级别，见 §4）。
- **超纲词（violation）**：正文中不属于「词汇池 ∪ 本篇新词 ∪ 专有名词白名单 ∪ 数字词」的词。
- **已掌握（mastered）**：生词状态机终态，判定规则见 M7。
- **模板故事（template story）**：人工编写的故事，生成管线最终兜底用，非用户主动选择的内容来源。
- **免费额度**：自然日内可发起的「生成」次数，免费用户 1 次/天；买断用户无限。

## 3. 产品总览

### 3.1 定位
每天一篇只给你的孩子写的英语故事：按级别受控词汇现场生成、跟读有反馈、进度家长可见。一次买断。

### 3.2 双用户
家长（付费/管理，经家长门）与孩子（阅读，全屏儿童界面，无任何购买与设置入口）。

### 3.3 核心闭环
定级 → 选主题 → 生成（含校验）→ 朗读/自主读 → 跟读比对 → 理解题 → 新词入库与复现调度 → 家长报告。

### 3.4 商业模式
免费：每天 1 次生成 + 定级 + 已读重读不限。付费：$29.99 一次买断解锁无限生成与全部级别。无订阅、无广告。

### 3.5 MVP 明确不做
自然拼读课程、多孩子档案、账号与云同步、社交/排行榜/游戏化激励、中文双语讲解（仅点词释义）、自由文本输入（主题只能选不能输）、Android。

## 4. 分级体系规格（种子数据编写依据）

对齐 CEFR + 剑桥 YLE 公开词表 + Dolch 高频词表。

| 级别 | 对齐 | 累计词汇池 | 单篇词数 | 句长上限 | 每篇新词 | 允许时态/句型要点 |
|---|---|---|---|---|---|---|
| L1 | Pre-A1 / Starters 前 | ~150 | 40–60 | ≤5 词 | 2 | 一般现在时；I have / This is / I can / I like |
| L2 | Pre-A1 / Starters | ~300 | 80–130 | ≤8 词 | 3–4 | 现在时叙事 + 简单过去时（was/saw/went/gave）；Let's… |
| L3 | A1 / Movers 前 | ~500 | 130–180 | ≤10 词 | 4–5 | 过去时叙事；because / and then 连接 |
| L4 | A1 / Movers | ~750 | 180–250 | ≤12 词 | 5 | 比较级；going to；简单状语从句 |
| L5 | A1+ / Flyers 前 | ~1,000 | 250–320 | ≤14 词 | 5–6 | 一般将来时；when/if 入门 |
| L6 | A2 / Flyers | ~1,300 | 320–400 | ≤16 词 | 6 | 多句段落；直接引语；简单复合句 |

全局规则：
- G1 词汇池只增不减：高级别池 = 本级新增 ∪ 全部低级别池。
- G2 每级句型池 8–12 个句型模板，生成时只允许使用本级及以下句型。
- G3 晋升：本级词汇掌握率 ≥ 80% 时家长端出现晋升提示，家长确认后晋升，**不自动跳级、不降级**（家长手动改级除外）。
- G4 v1.0 上线范围 L1–L6 全部六级种子数据（词汇池/句型池/定级题/模板故事）；如工期压缩，允许 L4–L6 模板故事先行每级 5 篇，其余数据必须齐全。

## 5. 页面清单（信息架构）

| ID | 页面 | 使用者 | 说明 |
|---|---|---|---|
| P01 | 欢迎/启动页 | 家长 | 价值一句话 + 「开始定级」；已有档案时自动跳 P04 |
| P02 | 家长门 | 家长 | 长按 2 秒 + 算术题验证（见 M1） |
| P03 | 定级测试页 | 孩子答题/家长看结果 | 答题子页 + 结果子页（级别、依据、开始阅读 CTA） |
| P04 | 孩子端首页 | 孩子 | 今日故事大按钮、继续读（未读完的故事）、我的级别徽章 |
| P05 | 主题选择页 | 孩子 | 12 个主题卡片（图标+英文名），无输入框 |
| P06 | 生成等待页 | 孩子 | 动画 + 「正在为你写故事…」；超时/兜底无感切换 |
| P07 | 阅读页 | 孩子 | 分页故事、朗读控制、点词释义卡 |
| P08 | 跟读页 | 孩子 | 逐句跟读、录音按钮、标词反馈 |
| P09 | 理解题页 | 孩子 | 3 道选择题逐题作答 |
| P10 | 完成页 | 孩子 | 鼓励语 + 本篇新词回顾（图+词） |
| P11 | 家长报告页 | 家长（门后） | 级别进度、本周数据、生词本入口、周报 |
| P12 | 生词本页 | 家长（门后） | 全量生词与状态 |
| P13 | 付费墙页 | 家长（门后触发） | 价格、权益、购买/恢复购买 |
| P14 | 设置页 | 家长（门后） | 小名、改级、语速、时长上限、清除数据、屏蔽列表 |
| P15 | 不支持机型说明页 | — | 非 Apple Intelligence 机型展示 |

导航规则：孩子端（P04–P10）为全屏线性流程，无底部 Tab；家长功能全部收敛在 P04 右上角家长入口 → P02 → P11/P12/P14。

---

## 6. 功能清单总表（交付范围以此为准）

优先级：P0 必做（缺失不发布）；P1 可砍（工期不足时按序砍 F-10.*）。

| ID | 模块 | 功能点 | 优先级 |
|---|---|---|---|
| F-01.1 | M1 启动与家长门 | 机型/系统能力检测与不支持说明页 | P0 |
| F-01.2 | M1 | 首次启动引导（1 页价值说明 + 隐私说明：无账号、不收集数据） | P0 |
| F-01.3 | M1 | 家长门：长按 2 秒 + 一道个位数算术题；答错可重试，无锁定 | P0 |
| F-01.4 | M1 | 家长会话：通过后 5 分钟内免重复验证，超时自动回锁 | P0 |
| F-02.1 | M2 定级测试 | 自适应答题引擎（规则见 §7 M2） | P0 |
| F-02.2 | M2 | 题型渲染：看词选图、听音选图、短句理解（三选一/四选一） | P0 |
| F-02.3 | M2 | 定级计算与结果页（级别 + 对齐说明 + 词汇量范围） | P0 |
| F-02.4 | M2 | 跳过定级：家长可直接手动选级（门后） | P0 |
| F-03.1 | M3 孩子端首页 | 今日故事入口（含免费额度剩余提示，仅家长可见文案，见 F-09.2） | P0 |
| F-03.2 | M3 | 继续读：存在未完成故事时置顶展示 | P0 |
| F-03.3 | M3 | 级别徽章展示（当前级别 + 本级进度小环，仅展示不可点） | P0 |
| F-04.1 | M4 故事生成 | 主题选择（12 主题白名单，卡片式） | P0 |
| F-04.2 | M4 | 生成参数组装（级别、新词候选、到期复习词、主角名） | P0 |
| F-04.3 | M4 | 结构化生成（标题/正文段落/新词列表） | P0 |
| F-04.4 | M4 | 生成后校验管线（超纲校验、安全过滤、自动替换，算法 A1） | P0 |
| F-04.5 | M4 | 重生成与模板兜底（最多重生成 2 次 → 模板库随机取未读篇） | P0 |
| F-04.6 | M4 | 插图生成（ImagePlayground，失败用级别默认图） | P0 |
| F-04.7 | M4 | 生成等待页（进度动画；30 秒超时自动切模板库） | P0 |
| F-05.1 | M5 阅读器 | 分页阅读（每页 2–4 句，正文 ≥24pt） | P0 |
| F-05.2 | M5 | 整篇朗读（TTS 逐句高亮同步） | P0 |
| F-05.3 | M5 | 点句朗读（点任意句单独朗读该句） | P0 |
| F-05.4 | M5 | 点词释义卡（中文释义 + 发音按钮 + 新词标记） | P0 |
| F-05.5 | M5 | 阅读进度记录（读完判定：到达末页且停留 ≥3 秒） | P0 |
| F-06.1 | M6 跟读 | 逐句跟读录音（按住/点按录音，单句最长 15 秒） | P0 |
| F-06.2 | M6 | 本地转写与逐词比对（算法 A3） | P0 |
| F-06.3 | M6 | 标词反馈（漏读/疑似错词标黄，点词听正确发音；不出现分数与「错误」字样） | P0 |
| F-06.4 | M6 | 低置信度降级（仅完成鼓励反馈，不标词） | P0 |
| F-06.5 | M6 | 录音即用即删（比对后立即删除音频，不落盘持久化） | P0 |
| F-06.6 | M6 | 跳过跟读（每句可跳过，整段可跳过进理解题） | P0 |
| F-07.1 | M7 生词与复习 | 新词自动入库（状态机 new→reviewing→mastered） | P0 |
| F-07.2 | M7 | 复现调度（1/3/7 天间隔，到期词优先进下一篇新词候选） | P0 |
| F-07.3 | M7 | 掌握判定（3 篇不同故事出现 + 词义题答对 ≥1 次） | P0 |
| F-07.4 | M7 | 家长生词本（全量、状态、按状态筛选） | P0 |
| F-08.1 | M8 理解题 | 题目生成（3 道，题型模板约束，算法见 §7 M8） | P0 |
| F-08.2 | M8 | 题目校验（答案须在原文可定位；不通过换人工兜底题） | P0 |
| F-08.3 | M8 | 答题交互（答错高亮原文相关句；第二次答错显示答案） | P0 |
| F-08.4 | M8 | 结果回写（词义题对错影响生词状态） | P0 |
| F-09.1 | M9 付费 | 免费额度计数（本地自然日，生成发起时扣减） | P0 |
| F-09.2 | M9 | 付费墙触发与展示（第 2 次生成时；先过家长门） | P0 |
| F-09.3 | M9 | 买断购买（StoreKit 2）与恢复购买 | P0 |
| F-09.4 | M9 | 购买状态校验（交易监听，防重复解锁提示） | P0 |
| F-10.1 | M10 家长端 | 报告页（级别进度、本周新词/时长/篇数、最近 5 篇） | P0 |
| F-10.2 | M10 | 周报生成（每周日首次打开家长端时生成，一页图文） | P1 |
| F-10.3 | M10 | 晋升提示（掌握率 ≥80% 时展示，家长确认晋升） | P0 |
| F-10.4 | M10 | 屏蔽故事（报告页/历史中对单篇「不再出现」，本地记录） | P0 |
| F-10.5 | M10 | 设置（小名、手动改级、语速、每日时长上限） | P0 |
| F-10.6 | M10 | 清除全部数据（二次确认，删档案/记录/生词，保留购买状态） | P0 |
| F-11.1 | M11 统计 | 本地事件计数（打开、定级完成、生成、读完、付费墙曝光/点击），不回传 | P1 |

---

## 7. 功能详细规格

### M1 启动与家长门
- F-01.1 能力检测顺序：系统版本 ≥ iOS 26 → `SystemLanguageModel.default.availability` 可用 → 否则显示 P15（文案：需要 iPhone 15 Pro 或更新机型）。SpeechAnalyzer 不可用时仅禁用 M6 并在设置页注明，不阻塞其余流程。
- F-01.3 家长门触发点：P04 家长入口、P13 购买、P14 设置、P11 报告。算术题为个位数加减（如 7+5），输入数字键盘；答错震动提示并换一题，不计次、不锁定。
- F-01.4 家长会话：验证通过时间戳存内存（不落盘），5 分钟内同一会话免验证；App 退后台超过 60 秒立即失效。

### M2 定级测试
- 题库：人工编写，每级 ≥ 20 题，三种题型比例约 4:3:3；题目结构见 §8 D5。
- 自适应规则：从 L2 难度起测；答对 +1 档、答错 −1 档（档位 = 级别内题序难度）；共 16 题或连续 3 题同级全对/全错时提前结束。
- 定级计算：取「正确率 ≥ 70% 的最高级别」为定级；全部低于 70% 定 L1；L6 正确率 ≥ 70% 定 L6。
- 结果页（家长看）：级别、对齐标准（CEFR/YLE）、该级词汇量范围、「开始阅读」CTA；同时提供「手动调整」（进 P02 后改级）。
- 中途退出：不保存进度，下次从头测；已有档案者不再强制测。

### M3 孩子端首页
- 元素：问候语（孩子小名）、级别徽章、「今日故事」大按钮、继续读卡片（条件显示）、家长入口（右上角小图标）。
- 免费额度提示**不对孩子展示**；额度用完时孩子点「今日故事」→ 显示「今天的故事已经读完啦，明天再来」页，页内小字引导「让爸爸妈妈点这里」进家长门 → 付费墙。不得在孩子端出现价格与购买按钮。

### M4 故事生成（核心管线，严格按 A1 实现）
- F-04.1 主题白名单（v1 固定 12 个，含图标与英文名）：Animals 小动物、Dinosaurs 恐龙、Space 太空、Ocean 海洋、Trains 火车、Food 食物、Sports 运动、Seasons 季节、Family 家庭、Friends 朋友、Farm 农场、Colors & Shapes 颜色形状。
- F-04.2 参数组装：
  - 级别 = 孩子当前级别；
  - 新词候选 = 到期复习词（M7 调度，优先）+ 本级未掌握新词，总数按 §4 本篇新词数，先复习词后新词；
  - 主角名 = 孩子小名（家长未设置时用默认角色 "Pip" 小狐狸）；
  - 句型白名单 = 本级及以下句型池。
- F-04.3 结构化输出（@Generable）：`StoryDraft { title: String, paragraphs: [String]（3–6 段）, newWordsUsed: [String] }`；提示词模板见 §9 T1。
- F-04.5 兜底顺序：校验失败 → 自动替换（同义词映射表，见 §8 D7）后复检 → 整篇重生成（换随机种子，最多 2 次）→ PCC 配置重生成 1 次 → 模板库取同级未读篇（无未读则取读过最久远一篇）。全程对孩子无感知，等待页不展示失败信息。
- F-04.6 插图：以「主题 + 主角 + 标题」组提示生成 1 张；生成失败/超时 8 秒用级别默认图（6 张随包）。
- 数据落库：故事全文、新词、来源标记（model/template）、级别、创建时间、读完状态。

### M5 阅读器
- 分页：按段落与句数切页，每页 2–4 句；插图在第一页顶部。
- F-05.2 朗读：逐句入队 AVSpeechSynthesizer，速率由设置决定（慢 0.42 / 正常 0.5，AVSpeechUtterance rate 参考值，编码时以真机听感校准）；朗读中当前句背景高亮；可暂停/继续/停止；朗读完自动停在末页。
- F-05.4 点词释义来源优先级：① 本地词条库（§8 D2，含音标与中文释义）直接查；② 缺失时由 FM 现场生成释义并缓存进本地词条（标记 source=generated，下次直接用）；③ 再失败只显示发音按钮。生词（本篇新词）在正文中以圆点下划线标记，释义卡带「新词」徽章。
- F-05.5 读完判定触发后：解锁「跟读」与「理解题」入口（完成页流程），并回写 ReadingSession 时长。

### M6 跟读比对（算法 A3）
- 流程：逐句呈现 → 点录音 → 录音中显示声波动画 → 松开/点停结束（单句上限 15 秒自动停）→ 转写比对 → 反馈呈现（标黄词列表以词卡形式展示，点词卡听 TTS 正确发音）→ 下一句。
- 比对规则（A3）：目标句与转写均做归一化（小写、去标点、缩略形式展开表）；做词级最长公共子序列对齐；目标词未被对齐到 → 候选漏读/错读；每句最多标 3 个词（取句中靠前者）。
- 置信度：取转写结果平均置信度 < 0.55 → 本句走 F-06.4 降级（只显示完成鼓励，不标词）。
- 隐私：音频只存在内存/临时目录，比对完成立即删除并清空引用；代码审查项——任何路径不得把音频写入 SwiftData 或 Documents 持久区。

### M7 生词与复习
- 状态机：`new`（本篇引入）→ `reviewing`（已进入复现调度）→ `mastered`（满足 F-07.3）；无逆向（家长可在生词本手动重置单个词为 reviewing，P1 不做，v1 不提供）。
- 调度：词进入 reviewing 后，下次应复现日 = +1 天；每次在新故事中实际出现后顺延：1 → 3 → 7 天；到期未被选入故事则继续顺延到下一篇（不堆积惩罚）。
- 选词（供 F-04.2）：到期词按到期日升序取，数量 ≤ 本篇新词配额的 1/2（至少 1 个，若有到期词），其余配额给全新词（从本级词汇池中孩子未见过的词按词频序取）。
- F-07.3 掌握判定：该词在 ≥ 3 篇不同故事中出现过，且其词义题（M8）累计答对 ≥ 1 次 → mastered；mastered 词移出候选池但仍可在故事中自然出现。

### M8 理解题
- 题量与题型：每篇 3 道 = 细节题 1（文中可定位）+ 词义题 1（从本篇新词中取 1 词，问中文/图义，四选一）+ 理解/判断题 1。
- 生成：FM 按模板 T2 生成结构化题目 `QuizItem { type, question, options[4], correctIndex, evidenceSentence }`；evidenceSentence 必须是正文原句（逐字比对校验）。
- 校验失败（答案不在原文/选项重复/evidence 不匹配）→ 该题替换为人工兜底题（每级按故事主题预置，见 §8 D6）；3 道全失败则整组用兜底题组。
- 交互：选错 → 高亮 evidence 句所在页片段并提示「看看这一句」；同一题第二次选错 → 直接显示正确答案与 evidence；结果回写：词义题对错写 WordRecord，细节/理解题结果写 ReadingSession。

### M9 付费
- F-09.1 额度计数：UserDefaults 存 `lastGenDate` 与 `genCountToday`；发起生成（点主题确认）时若免费用户且 count ≥ 1 且日期为今日 → 走付费墙流程；生成失败走模板兜底的**不扣额度**（以最终交付来源判定：来源 = template 且原因为生成失败时不扣；用户额度已用完后主动读模板故事功能 v1 不提供，不在此列）。
- F-09.2 付费墙：必须先过家长门；页面一页说清：价格 $29.99 一次买断、无订阅、无广告、不收集数据、支持家庭共享；含恢复购买入口。
- F-09.3/4 StoreKit 2：`Transaction.currentEntitlements` 启动校验 + `Transaction.updates` 监听；购买成功即时解锁并回孩子端继续原流程（回到主题选择）。
- 价格本地化：价格字符串一律取 StoreKit `Product.displayPrice`，文案中 $29.99 仅为美区定价基准，不得硬编码到 UI。

### M10 家长端
- F-10.1 报告字段：当前级别与本级掌握进度（mastered+reviewing 中已见词 / 本级池总数）、本周（自然周）新词数、阅读总时长、读完篇数、最近 5 篇（标题/级别/日期/新词数），点单篇可看全文与「不再出现」按钮（F-10.4）。
- F-10.2 周报：每周日家长首次进报告页时用 FM 按模板 T3 生成 3–5 句摘要（基于本周本地数据），配本地绘制的简单条形数据（新词/时长）；生成失败则只显示数据区。
- F-10.3 晋升：掌握率 ≥ 80% 时报告页顶部出现晋升卡（目标级别与对齐说明），家长点确认才晋升；晋升后新词候选池切换至新级别。
- F-10.5 设置项：孩子小名（文本，≤ 12 字符）、手动改级（L1–L6，需二次确认，提示会影响故事难度）、朗读语速（慢/正常）、每日时长上限（关/15/30/45 分钟；达到上限孩子端显示休息页，次日恢复；**时长限制只拦新故事，不中断正在读的一篇**）。
- F-10.6 清除数据：二次确认（输入算术题）后删除 ChildProfile、Story、WordRecord、ReadingSession；保留 PurchaseState 与 App 设置中的购买解锁状态。

### M11 本地统计（P1）
- 事件：app_open、placement_done、generate_start、story_delivered(source)、story_finished、paywall_shown、purchase_success。仅本地计数存 UserDefaults，设置页家长可查看与清零；无任何回传代码路径。

---

## 8. 数据模型与种子数据规格

### 8.1 运行时数据（SwiftData，全部本地）

**D-R1 ChildProfile**（单例，v1 只有一个）
| 字段 | 类型 | 说明 |
|---|---|---|
| nickname | String | 孩子小名，≤12 字符，可空（空则主角用默认角色 Pip） |
| level | Int (1–6) | 当前级别 |
| placementDone | Bool | 是否完成过定级 |
| placementLevel | Int? | 最近一次定级结果（与 level 可不同：家长手动改级后 level 以手动为准） |
| createdAt | Date | 建档时间 |

**D-R2 Story**
| 字段 | 类型 | 说明 |
|---|---|---|
| id | UUID | |
| title | String | |
| paragraphs | [String] | 正文段落，3–6 段 |
| level | Int | 生成时级别 |
| theme | String | 主题 key（见 F-04.1） |
| newWords | [String] | 本篇新词（lemma 形式） |
| source | Enum | model / template |
| illustrationName | String? | 插图本地文件名，nil 表示用级别默认图 |
| isFinished | Bool | 是否触发过读完判定 |
| isBlocked | Bool | 家长屏蔽（F-10.4） |
| createdAt | Date | |

**D-R3 WordRecord**（每个学过的词一条）
| 字段 | 类型 | 说明 |
|---|---|---|
| lemma | String | 主键，词元小写 |
| status | Enum | new / reviewing / mastered |
| firstSeenAt | Date | 首次引入日期 |
| nextReviewDate | Date | 下次应复现日（M7 调度） |
| reviewStage | Int | 已复现次数（决定 1/3/7 天间隔推进） |
| appearedStoryIds | [UUID] | 出现过的故事（掌握判定计数） |
| quizCorrectCount | Int | 词义题答对次数 |

**D-R4 ReadingSession**
| 字段 | 类型 | 说明 |
|---|---|---|
| storyId | UUID | |
| startedAt / finishedAt | Date / Date? | 时长 = 差值（家长报告用） |
| readAloudDone | Bool | 是否完成跟读流程（可跳过 = false） |
| flaggedWordCount | Int | 跟读标词总数（仅统计，不展示给孩子） |
| quizResults | [Bool] | 3 道题最终对错 |

**D-R5 PurchaseState**（单例）
| 字段 | 类型 | 说明 |
|---|---|---|
| isUnlocked | Bool | 买断状态，以 StoreKit 权益校验为准，本字段仅缓存 |
| productId | String | leveltales.fullaccess |

**UserDefaults 键**：`speechRate`（slow/normal）、`dailyTimeLimitMinutes`（0=不限）、`lastGenDate`、`genCountToday`、`parentGatePassedAt` 不落盘（仅内存）、`localStats`（M11 计数 JSON）。

### 8.2 种子数据（随包 JSON，首启导入，只读）

**D2 词条库 words.json**（点词释义 + 词汇池的唯一数据源）
```json
{ "lemma": "brave", "wordForms": ["brave", "braver", "bravest"],
  "pos": "adj", "phonetic": "/breɪv/", "zh": "勇敢的",
  "level": 2, "isSightWord": false, "frequencyRank": 412 }
```
- 字段说明：`wordForms` 含全部屈折形式，校验管线按 form→lemma 映射判定归属；`level` = 该词首次出现的级别；`frequencyRank` 供 M7 新词候选排序。
- 数量要求：六级累计 ≈1,300 词条（按 §4 各级累计词汇池），每条必须有 zh 释义与音标（人工/词典导入后人工抽检 10%）。

**D3 句型池 patterns.json**
```json
{ "level": 2, "patterns": ["I see a ___.", "___ is ___ than ___.", "Let's ___ ."] }
```
每级 8–12 条，`___` 为填空槽。生成提示词 T1 注入本级及以下全部句型。

**D5 定级题库 placement.json**
```json
{ "id": "pl-l2-003", "level": 2, "type": "wordToImage",
  "promptText": "Which picture shows a 'cave'?",
  "promptAudio": true,
  "options": [{"image": "img_cave", "isCorrect": true},
              {"image": "img_house", "isCorrect": false},
              {"image": "img_tree", "isCorrect": false}] }
```
- type 枚举：wordToImage（看词选图，promptText 为英文词/句，选项为图）、audioToImage（听音选图，先播 TTS 再选图）、sentenceComp（短句理解，promptText 为短句，选项为图或短句）。
- 每级 ≥ 20 题；选项图片为随包素材（简笔图标风，每题 3–4 张，可跨题复用图库）。

**D6 理解题兜底题库 quiz_fallback.json**：按「级别 × 主题」预置，每组合 ≥ 2 组（每组 3 道，结构同 §7 M8 的 QuizItem，evidenceSentence 允许为空——兜底题与模板故事绑定时用模板故事原句，独立使用时 evidence 显示题干句）。与 D8 模板故事配套交付。

**D7 同义词替换表 synonyms.json**（校验管线自动替换用）
```json
{ "enormous": "big", "terrified": "scared", "purchase": "buy" }
```
- 左为常见超纲词，右为必须在 L3 及以下词汇池内的简单词；首版 ≥ 150 对，人工整理。
- 替换时保持原句大小写与标点位置；替换后必须复检。

**D8 模板故事库 template_stories.json**
```json
{ "id": "tpl-l2-dino-01", "level": 2, "theme": "dinosaurs",
  "title": "...", "paragraphs": ["...", "..."],
  "newWords": ["brave", "cave"], "quiz": [ /* 3 道 QuizItem */ ] }
```
- 每级 ≥ 10 篇（工期压缩时 L4–L6 可先行 5 篇，见 G4），覆盖本级全部主题中的至少 6 个；newWords 必须属于本级词汇池。

**D9 其他随包数据**：主题表 themes.json（12 主题：key/英文名/图标名）；黑名单 blacklist.json（儿童不宜词与话题词，人工维护，首版 ≥ 200 词）；缩略展开表 contractions.json（I'm→I am 等，A1/A3 归一化共用）；专有名词白名单 proper_nouns.json（孩子小名动态注入 + 常见人名/地名 ≈50）。

### 8.3 种子数据交付清单（编码前必须备齐，属内容工作非编码工作）
| 数据 | 数量 | 负责人建议 |
|---|---|---|
| D2 词条库 | ≈1,300 条 | 词表按 YLE 公开词表整理 + 词典批量导入，人工抽检 |
| D3 句型池 | 6 级 × 8–12 条 | 人工编写，英语老师过目 |
| D5 定级题 | 6 级 × ≥20 题 + 选项图库 | 人工编写，老师过目 |
| D6 兜底题 | 每级 × 每主题 ≥2 组（可与 D8 合并交付） | 人工编写 |
| D7 同义词表 | ≥150 对 | 人工整理 |
| D8 模板故事 | 每级 ≥10 篇 | 人工编写（可 AI 起草 + 人工逐词按词汇池改定） |
| D9 黑名单等 | 黑名单 ≥200 词 | 人工整理 |

---

## 9. 提示词模板（编码直接使用，变量以 {{ }} 标注）

### T1 故事生成（F-04.3）
系统指令（instructions，固定）：
```
You write short English stories for a child learning to read.
Follow every rule exactly:
1. Use ONLY words from the ALLOWED WORD LIST, plus the NEW WORDS listed. No other words.
2. Use ONLY sentence patterns from the ALLOWED PATTERNS list.
3. Every NEW WORD must appear at least 2 times in the story.
4. Keep every sentence at or under the MAX SENTENCE LENGTH.
5. The story must be kind and safe for a 4-8 year old. No scary, violent, or sad endings.
6. Write simple, clear sentences. One idea per sentence.
```
用户提示（每次组装）：
```
Write a story about {{themeName}}.
Main character name: {{heroName}}.
Target length: {{minWords}}-{{maxWords}} words, in {{paragraphCount}} short paragraphs.
NEW WORDS (must use each at least twice): {{newWords}}
ALLOWED WORD LIST: {{allowedWords}}
ALLOWED PATTERNS: {{allowedPatterns}}
MAX SENTENCE LENGTH: {{maxSentenceWords}} words.
```
结构化输出（@Generable）：
```swift
@Generable struct StoryDraft {
    @Guide(description: "Story title, max 5 words") var title: String
    @Guide(description: "3 to 6 short paragraphs") var paragraphs: [String]
    @Guide(description: "The new words actually used") var newWordsUsed: [String]
}
```
注：ALLOWED WORD LIST 全量注入可能超上下文（L6 累计 1,300 词约 2–3K tokens，可接受）；若实测超限，改为注入「本级池 + 低级别高频 500 词」并在校验端用全量池判定（生成端约束宽松、校验端严格，靠重生成收敛）。

### T2 理解题生成（F-08.1）
系统指令：
```
You create multiple-choice questions about a short children's story.
Rules:
1. Exactly 3 questions: one detail question, one word-meaning question, one understanding question.
2. The detail and understanding questions must be answerable from ONE sentence in the story. Return that exact sentence as evidenceSentence, copied word for word.
3. The word-meaning question asks about the given TARGET WORD: "What does '{{targetWord}}' mean?" with 4 options in Chinese, only one correct.
4. Other questions: question and options in simple English, using only words from the story.
5. Each question has exactly 4 options and exactly 1 correct answer. Wrong options must be clearly wrong but plausible.
```
用户提示：
```
STORY:
{{storyText}}
TARGET WORD: {{targetWord}} (correct Chinese meaning: {{targetWordZh}})
```
结构化输出：
```swift
@Generable struct QuizItem {
    var type: String            // detail / wordMeaning / understanding
    var question: String
    var options: [String]       // exactly 4
    var correctIndex: Int       // 0-3
    var evidenceSentence: String // detail/understanding 必填且须为正文原句；wordMeaning 可为空
}
@Generable struct QuizSet { var items: [QuizItem] }  // exactly 3
```

### T3 家长周报摘要（F-10.2）
系统指令：
```
You write a short weekly reading report for a parent, in Chinese.
Use ONLY the numbers given. Do not invent data. 3 to 5 sentences.
Tone: warm and factual. Mention: stories finished, new words learned, reading time, current level progress, and one encouragement.
```
用户提示：
```
本周数据：读完故事 {{stories}} 篇；新学单词 {{newWords}} 个；阅读时长 {{minutes}} 分钟；
当前级别 L{{level}}，本级词汇掌握进度 {{progressPercent}}%；
孩子小名：{{nickname}}。
```
输出：纯文本 String（非结构化即可），生成失败时周报只展示数据区（见 F-10.2）。

---

## 10. 核心算法伪代码

### A1 生成后校验管线（F-04.4 / F-04.5）
```
func validateStory(draft, level, expectedNewWords) -> Verdict:
    text = draft.paragraphs.join(" ")
    tokens = normalize(text)            // 小写、去标点、缩略展开(D9)、按 form→lemma 映射(D2)
    allowed = vocabPool(upTo: level) ∪ expectedNewWords ∪ properNouns ∪ numberWords
    violations = tokens where lemma ∉ allowed
    violationRate = violations.count / tokens.count

    if blacklistHit(tokens or rawText): return .unsafe        // 黑名单命中直接判不安全，不走替换
    if violationRate <= 0.02 and newWordsAllPresent(draft, expectedNewWords, minCount: 2):
        return .pass
    // 尝试自动替换
    if every violation has synonym in D7 and synonym ∈ allowed:
        draft' = replaceAll(draft, D7)
        if validateOnce(draft') passes thresholds: return .passWithReplacement(draft')
    return .fail

pipeline:
    for attempt in 1...3:                // 端侧 2 次 + PCC 1 次
        draft = generate(attempt)
        verdict = validateStory(draft)
        if verdict is pass: deliver(draft); return
    deliver(templateFallback(level, theme))   // 不扣免费额度（见 F-09.1）
```
阈值汇总：超纲率 ≤ 2%；新词每个出现 ≥ 2 次；黑名单零容忍；单篇校验耗时应 < 500ms（纯本地文本处理）。

### A2 生词选词与复现调度（F-04.2 / M7）
```
func pickNewWords(level, quota, today) -> [lemma]:
    due = WordRecords where status == reviewing and nextReviewDate <= today
          order by nextReviewDate asc
    reviewPicks = due.take(max(1, quota/2)) if due not empty else []
    fresh = vocabPool(level: level) where lemma not in WordRecords
            order by frequencyRank asc
    freshPicks = fresh.take(quota - reviewPicks.count)
    return reviewPicks + freshPicks

onStoryDelivered(story):
    for word in story.newWords:
        record = WordRecord(word) ?? create(status: new)
        if record.status == new: record.status = reviewing; record.reviewStage = 0
        else: record.reviewStage += 1
        record.nextReviewDate = today + interval[record.reviewStage]   // interval = [1, 3, 7, 7, ...] 天
        record.appearedStoryIds += story.id
        checkMastery(record)

checkMastery(record):
    if record.appearedStoryIds.uniqueCount >= 3 and record.quizCorrectCount >= 1:
        record.status = mastered
```

### A3 跟读逐词比对（F-06.2）
```
func compareReading(targetSentence, transcript, avgConfidence) -> Feedback:
    if avgConfidence < 0.55: return .encouragementOnly          // F-06.4 降级
    target = normalizeWords(targetSentence)                     // 同 A1 归一化
    heard  = normalizeWords(transcript)
    aligned = lcsAlignment(target, heard)                       // 词级最长公共子序列对齐
    missed = target words not aligned, in sentence order
    flagged = missed.take(3)                                    // 每句最多标 3 个
    return .flagged(flagged)
```
说明：LCS 对齐对儿童常见的重复读、自我修正（同词读两遍）天然宽容——重复词不影响对齐结果；漏读与明显错读不做区分，统一以「标黄 + 点听正确发音」呈现（见 F-06.3）。

---

## 11. 非功能需求

| 类别 | 要求 |
|---|---|
| 性能 | 生成全流程（点主题 → 可读）P95 ≤ 10 秒（端侧路径，不含 PCC 兜底）；校验管线 < 500ms；点词释义本地命中 < 300ms；冷启动到可交互 < 2 秒 |
| 离线 | 除 PCC 兜底外全部功能离线可用；无网络时 PCC 步骤自动跳过、直接走重生成/模板兜底 |
| 隐私 | 零数据收集：无账号、无第三方 SDK、无网络回传；儿童录音即用即删（F-06.5）；隐私标签申报「Data Not Collected」 |
| 可靠性 | 生成/校验/转写任一环节异常不得崩溃或卡死孩子端，一律降级到模板/鼓励反馈路径；SwiftData 写入失败时内存态继续本篇流程 |
| 无障碍 | 正文字号 ≥ 24pt 且支持系统大字号缩放不溢出；主要按钮点击区 ≥ 56pt（儿童手指）；朗读高亮兼顾色弱（高亮 + 下划线双通道） |
| 本地化 | v1 界面双语：孩子端英文为主（学英语场景）+ 图标辅助；家长端中文（可切换英文，P1） |
| 包体 | 种子数据 + 图库随包，目标总包体 ≤ 150MB |

## 12. 验收测试清单（发布前逐项过，P0 用例全过才可提交审核）

| ID | 模块 | 用例 | 预期 |
|---|---|---|---|
| T-01 | M1 | 非 Apple Intelligence 机型启动 | 显示 P15 说明页，无崩溃、无后续流程入口 |
| T-02 | M1 | 家长门答错算术题 3 次 | 每次换题可重试，无锁定 |
| T-03 | M1 | 家长验证后退后台 61 秒回前台 | 再次进入家长功能需重新验证 |
| T-04 | M2 | 模拟全对答题（高难度路径） | 定级 L5–L6，题数 ≤ 16 |
| T-05 | M2 | 模拟全错答题 | 定级 L1 |
| T-06 | M2 | 定级中途杀进程重进 | 不保存进度，从头测或跳过 |
| T-07 | M4 | 正常生成一篇 L2 故事 | ≤10 秒出文；新词各出现 ≥2 次；超纲率 ≤2% |
| T-08 | M4 | 断网 + 模拟端侧生成连续失败 | 最终交付模板故事，孩子端无报错，免费额度不扣减 |
| T-09 | M4 | 抽测生成 100 篇（L1–L3） | 超纲率 ≤2%，黑名单漏检 0，模板兜底率 ≤10% |
| T-10 | M4 | 插图生成超时 | 8 秒后用级别默认图，阅读流程不阻塞 |
| T-11 | M5 | 点生词与普通词 | 释义卡正确，生词带徽章；本地命中响应 <300ms |
| T-12 | M5 | 整篇朗读 | 逐句高亮与语音同步，无跳句 |
| T-13 | M6 | 成人按原文朗读一句 | 无标词或仅标个别词（测试集词级准确率 ≥90%） |
| T-14 | M6 | 故意漏读 2 个词 | 标出漏读词 ≤3 个，点词可听发音 |
| T-15 | M6 | 嘈杂环境跟读 | 走鼓励反馈，不标词 |
| T-16 | M6 | 跟读后检查设备存储 | 无残留音频文件 |
| T-17 | M7 | 生词按 1/3/7 天调度 | 到期词优先进入下一篇新词（构造数据验证） |
| T-18 | M7 | 词在 3 篇出现 + 词义题答对 | 状态变 mastered，移出候选池 |
| T-19 | M8 | 理解题 evidence 校验 | 生成题 evidence 与正文逐字一致；不一致的题被兜底题替换 |
| T-20 | M8 | 同一题连续答错 2 次 | 第一次高亮原文句，第二次显示答案 |
| T-21 | M9 | 免费用户当日第 2 次生成 | 先过家长门再到付费墙，孩子端不出现价格 |
| T-22 | M9 | 沙盒购买 + 删 App 重装恢复购买 | 解锁状态正确恢复 |
| T-23 | M9 | 额度跨日 | 次日 0 点后免费额度恢复 1 次 |
| T-24 | M10 | 掌握率达 80% | 报告页出现晋升卡，确认后级别切换 |
| T-25 | M10 | 设置每日时长上限 15 分钟并用满 | 拦新故事不中断当前篇，次日恢复 |
| T-26 | M10 | 清除全部数据 | 档案/故事/生词清空，购买解锁保留 |
| T-27 | 全局 | 飞行模式全流程（定级→生成→读→题） | 除 PCC 外功能正常（生成走端侧/模板） |
| T-28 | 全局 | Kids 合规自查 | 无第三方 SDK、无外链、无儿童端购买入口，隐私标签为不收集数据 |

## 13. 开发任务拆分与里程碑（承接六周路线，供编码排期）

| 周 | 编码任务 | 依赖/并行内容工作 |
|---|---|---|
| 0 | —（验证期） | 落地页验证结论回填 §3.4；种子数据启动编写 |
| 1 | 工程脚手架、种子数据导入、M1 家长门、M2 定级 | D2/D3/D5 数据交付（L1–L3 先行） |
| 2 | M4 生成管线（T1 + A1 + 兜底）、M5 阅读器 | D7/D8/D9 交付；生成质量抽测（T-09 预演） |
| 3 | M6 跟读（A3）、M8 理解题（T2 + 校验）、M7 生词调度（A2） | D6 兜底题交付 |
| 4 | M10 家长端（报告/周报 T3/设置）、M9 付费全链路 | App Store Connect 产品创建、价格设定 |
| 5 | 内测版（TestFlight）+ §12 用例全量回归 | 5–10 个真实家庭内测 |
| 6 | 修内测问题、合规自查（T-28）、提交审核 | 商店素材（截图/描述，突出端侧 + 买断） |

## 14. 未决问题与假设（编码方遇到时按「假设」执行，不要自行改规格）

1. **定价假设**：$29.99 买断为当前假设，付费意愿验证结论（2026-12-09）如要求改订阅或改价，只动 M9 与付费墙文案，功能规格不变。
2. **Bundle ID / 产品 ID**：Bundle ID 待开发者账号确定；内购产品 ID 暂用 `leveltales.fullaccess` 占位，提审前统一替换。
3. **PCC 可用性假设**：iOS 27 PCC 模型若在目标系统版本不可用，A1 管线自动退化为「端侧 2 次 → 模板」，代码须以能力检测分支实现，不得假设 PCC 必然存在。
4. **儿童语音实测**：A3 的置信度阈值 0.55 与「每句最多标 3 词」为初始值，内测后可调参（只调常量，不改算法结构）；若儿童实测误标率 > 20%，按 PRD 既定对策将 M6 降级为仅完成反馈模式（保留录音转写链路，关闭标词展示）。
5. **词条库释义来源**：D2 的 zh 释义与音标以公开词表 + 通用词典数据整理为准，编码方不需要、也不得在运行时调用任何在线词典 API（零网络约束）。
6. **商标**：LevelTales 商标检索未做，提审前由产品方完成；如需改名，只涉及品牌字符串与素材，不涉及功能。

---

*文档完。交付范围 = §6 功能清单总表（P0 全量 + P1 视工期）；验收标准 = §12；数据与模板 = §8/§9；算法口径 = §10。*
