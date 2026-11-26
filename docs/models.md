# 数据模型（Swift 代码级定义，可直接粘贴后按需微调）

## SwiftData 运行时模型
```swift
import SwiftData
import Foundation

@Model final class ChildProfile {
    var nickname: String = ""
    var level: Int = 1                 // 1...6
    var placementDone: Bool = false
    var placementLevel: Int? = nil
    var createdAt: Date = Date()
    init() {}
}

enum StorySource: String, Codable { case model, template }

@Model final class Story {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var paragraphs: [String] = []
    var level: Int = 1
    var theme: String = ""             // themes.json 的 key
    var newWords: [String] = []        // lemma
    var sourceRaw: String = StorySource.model.rawValue
    var illustrationName: String? = nil
    var isFinished: Bool = false
    var isBlocked: Bool = false
    var createdAt: Date = Date()
    var source: StorySource { StorySource(rawValue: sourceRaw) ?? .model }
}

enum WordStatus: String, Codable { case new, reviewing, mastered }

@Model final class WordRecord {
    @Attribute(.unique) var lemma: String = ""
    var statusRaw: String = WordStatus.new.rawValue
    var firstSeenAt: Date = Date()
    var nextReviewDate: Date = Date()
    var reviewStage: Int = 0
    var appearedStoryIds: [UUID] = []
    var quizCorrectCount: Int = 0
    var status: WordStatus { WordStatus(rawValue: statusRaw) ?? .new }
    init(lemma: String) { self.lemma = lemma }
}

@Model final class ReadingSession {
    var storyId: UUID = UUID()
    var startedAt: Date = Date()
    var finishedAt: Date? = nil
    var readAloudDone: Bool = false
    var flaggedWordCount: Int = 0
    var quizResults: [Bool] = []
}

@Model final class PurchaseState {
    var isUnlocked: Bool = false       // 仅缓存，真值以 StoreKit 权益为准
    var productId: String = "leveltales.fullaccess"
    init() {}
}
```

## 种子数据 Codable 结构（与 seed/*.json 一一对应）
```swift
struct WordEntry: Codable {
    let lemma: String
    let wordForms: [String]            // 含 lemma 本身及全部屈折形式，小写
    let pos: String
    let phonetic: String
    let zh: String
    let level: Int                     // 首次出现级别
    let isSightWord: Bool
    let frequencyRank: Int
}
struct PatternBank: Codable { let level: Int; let patterns: [String] }
struct PlacementItem: Codable, Identifiable {
    let id: String; let level: Int; let type: String  // wordToImage|audioToImage|sentenceComp
    let promptText: String; let promptAudio: Bool
    struct Option: Codable { let image: String; let text: String?; let isCorrect: Bool }
    let options: [Option]
}
struct QuizItemSeed: Codable {
    let type: String                   // detail|wordMeaning|understanding
    let question: String; let options: [String]
    let correctIndex: Int; let evidenceSentence: String
}
struct TemplateStory: Codable, Identifiable {
    let id: String; let level: Int; let theme: String
    let title: String; let paragraphs: [String]
    let newWords: [String]; let quiz: [QuizItemSeed]
}
struct ThemeItem: Codable, Identifiable { let key: String; let en: String; let zh: String; let icon: String; var id: String { key } }
```

## 内存索引（SeedImporter 导入后构建，供校验/释义/选词高速查询）
```swift
final class Lexicon {
    private(set) var entriesByLemma: [String: WordEntry] = [:]
    private(set) var lemmaByForm: [String: String] = [:]     // form -> lemma
    private(set) var patternsByLevel: [Int: [String]] = [:]
    func pool(upTo level: Int) -> Set<String>                // <= level 的全部 lemma
    func allowedForms(upTo level: Int) -> Set<String>        // <= level 的全部 wordForms
}
```

## UserDefaults 键（集中定义，禁止散落字符串）
```swift
enum Prefs {
    static let speechRate = "lt.speechRate"               // slow|normal
    static let dailyTimeLimit = "lt.dailyTimeLimit"       // Int 分钟, 0=不限
    static let lastGenDate = "lt.lastGenDate"             // yyyy-MM-dd 本地
    static let genCountToday = "lt.genCountToday"         // Int
    static let seedVersion = "lt.seedVersion"             // Int
    static let stats = "lt.stats"                         // [String:Int] JSON
    static let todayReadSeconds = "lt.todayReadSeconds"   // 当日累计阅读秒数(时长上限用), 带日期键校验
    static let todayReadDate = "lt.todayReadDate"
}
```
