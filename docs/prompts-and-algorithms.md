# 提示词模板与核心算法

## T1 故事生成
instructions（固定）：
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
prompt 组装：
```
Write a story about {{themeName}}.
Main character name: {{heroName}}.
Target length: {{minWords}}-{{maxWords}} words, in {{paragraphCount}} short paragraphs.
NEW WORDS (must use each at least twice): {{newWords}}
ALLOWED WORD LIST: {{allowedWords}}
ALLOWED PATTERNS: {{allowedPatterns}}
MAX SENTENCE LENGTH: {{maxSentenceWords}} words.
```
@Generable 输出：
```swift
@Generable struct StoryDraft {
    @Guide(description: "Story title, max 5 words") var title: String
    @Guide(description: "3 to 6 short paragraphs") var paragraphs: [String]
    @Guide(description: "The new words actually used") var newWordsUsed: [String]
}
@Generable struct QuizItem {
    var type: String; var question: String; var options: [String]
    var correctIndex: Int; var evidenceSentence: String
}
@Generable struct QuizSet { var items: [QuizItem] }
```
级别参数（minWords/maxWords/paragraphCount/maxSentenceWords/newWords 配额）取 PRD §4 分级表。allowedWords 超上下文时按 PRD §9 注记降级注入（本级池 + 低级别高频 500），校验端始终用全量池。

## T2 理解题
instructions：
```
You create multiple-choice questions about a short children's story.
Rules:
1. Exactly 3 questions: one detail question, one word-meaning question, one understanding question.
2. The detail and understanding questions must be answerable from ONE sentence in the story. Return that exact sentence as evidenceSentence, copied word for word.
3. The word-meaning question asks about the given TARGET WORD: "What does '{{targetWord}}' mean?" with 4 options in Chinese, only one correct.
4. Other questions: question and options in simple English, using only words from the story.
5. Each question has exactly 4 options and exactly 1 correct answer. Wrong options must be clearly wrong but plausible.
```
prompt：`STORY:\n{{storyText}}\nTARGET WORD: {{targetWord}} (correct Chinese meaning: {{targetWordZh}})`

## T3 家长周报
instructions：
```
You write a short weekly reading report for a parent, in Chinese.
Use ONLY the numbers given. Do not invent data. 3 to 5 sentences.
Tone: warm and factual. Mention: stories finished, new words learned, reading time, current level progress, and one encouragement.
```
prompt：`本周数据：读完故事 {{stories}} 篇；新学单词 {{newWords}} 个；阅读时长 {{minutes}} 分钟；当前级别 L{{level}}，本级词汇掌握进度 {{progressPercent}}%；孩子小名：{{nickname}}。`

## A1 校验管线（ValidationService + GenerationPipeline 编排）
```
validate(text, level, expectedNewWords):
    tokens = normalize(text)   // lowercase → strip punctuation → expand contractions(seed/contractions.json)
                               // → map each form to lemma via Lexicon.lemmaByForm (未命中则 form 本身记为 lemma)
    allowedLemmas = lexicon.pool(upTo: level) ∪ expectedNewWords ∪ properNouns ∪ numberWords(0-100 英文)
    violations = unique lemmas of tokens where lemma ∉ allowedLemmas
    violationRate = (token count whose lemma ∈ violations) / tokens.count
    unsafe = any token lemma ∈ blacklist OR lowercase raw text contains blacklist phrase
    missingNew = expectedNewWords where count of any form in tokens < 2
    passed = !unsafe && violationRate <= 0.02 && missingNew.isEmpty

pipeline(level, theme):
    picks = ReviewScheduler.pickNewWords(level, quota(level), today)
    for attempt in 1...3:                       // 1-2 端侧, 3 PCC 配置
        draft = model.generateStory(prompt(level, theme, picks))
        r = validate(join(draft.paragraphs), level, picks)
        if r.passed: return save(draft, source: .model)
        if !r.unsafe && all violations replaceable via synonyms:
            fixed = applySynonyms(text, r.violations)
            if validate(fixed).passed: return save(fixed, source: .model)
    tpl = random unread TemplateStory(level, theme) ?? least-recently-read TemplateStory(level)
    return save(tpl, source: .template, chargeQuota: false)
```
测试向量（单测必须覆盖）：
- V1：text="I have a dog. The dog is brave. The brave dog can run."，level=1，expected=[brave]（brave 为 L2 词但作为 expectedNewWords 允许）→ dog/run/have/can ∈ L1 池 → passed=true（brave 出现 2 次 ✓）。
- V2：同上但 brave 只出现 1 次 → missingNew=[brave]，passed=false。
- V3：text 含 "enormous"（不在池、有同义词 big）→ 首次 validate 不通过 → applySynonyms 后通过。
- V4：text 含黑名单词 → unsafe=true，同义词路径不得执行。

## A2 选词与复现调度（ReviewScheduler）
```
pickNewWords(level, quota, today):
    due = WordRecords(status=reviewing, nextReviewDate<=today) sorted by nextReviewDate asc
    reviewPicks = due.prefix(due.isEmpty ? 0 : max(1, quota/2))
    fresh = lexicon entries(level == 当前级别, lemma ∉ WordRecords) sorted by frequencyRank asc
    return reviewPicks + fresh.prefix(quota - reviewPicks.count)

recordStoryDelivered(story):
    for lemma in story.newWords:
        rec = getOrCreate(lemma, status: .new)
        if rec.status == .new { rec.status = .reviewing; rec.reviewStage = 0 }
        else { rec.reviewStage += 1 }
        rec.nextReviewDate = today + [1,3,7][min(rec.reviewStage, 2)] days
        rec.appearedStoryIds ∪= {story.id}
        if rec.appearedStoryIds.count >= 3 && rec.quizCorrectCount >= 1 { rec.status = .mastered }
```
测试向量：quota=4、有 3 个到期词 → reviewPicks=2（max(1, 4/2)=2），fresh 补 2；无到期词 → fresh 4 个。

## A3 跟读比对（ReadAloudService）
```
compare(target, transcript, avgConfidence):
    if avgConfidence < 0.55: return .encouragementOnly
    t = normalizeWords(target); h = normalizeWords(transcript)   // 与 A1 同一归一化
    aligned = lcs(t, h)                                            // 词级最长公共子序列
    missed = t 中未被 aligned 覆盖的词（保序）
    return .flagged(Array(missed.prefix(3)))
```
测试向量：
- C1：target="the brave dog can run"，transcript="the brave dog run"，conf=0.9 → missed=[can] → flagged([can])。
- C2：target 同上，transcript="the the brave dog can run run"（重复读），conf=0.9 → missed=[] → flagged([])。
- C3：conf=0.4 → encouragementOnly（不比对）。
