import Foundation

// MARK: - 分类

enum NoteCategory: String, Codable, CaseIterable, Identifiable {
    case mention, promise, want, date, like

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mention: return "随口一提"
        case .promise: return "答应了她"
        case .want:    return "她想要的"
        case .date:    return "重要日子"
        case .like:    return "她的喜好"
        }
    }

    var emoji: String {
        switch self {
        case .mention: return "💬"
        case .promise: return "🤝"
        case .want:    return "🎁"
        case .date:    return "📅"
        case .like:    return "💗"
        }
    }
}

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case none, daily, weekly, monthly, yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "不重复"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .yearly: return "每年"
        }
    }
}

// MARK: - 数据模型

struct NoteItem: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var text: String = ""
    var category: NoteCategory = .mention
    var createdAt: Date = Date()
    var dueAt: Date? = nil
    var leadDays: Int = 1
    var repeatRule: RepeatRule = .none
    var dailyReview: Bool = true
    var done: Bool = false
    var note: String = ""
    var demo: Bool = false
    var snoozeUntil: Date? = nil
}

struct CustomDay: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var month: Int = 1
    var day: Int = 1
    var emoji: String = "🎂"
    var hint: String = ""
    var yearly: Bool = true
}

struct AppSettings: Codable {
    var leadDays: Int = 5
    var dailyHour: Int = 20
    var dailyMinute: Int = 30
    var danmakuSpeed: Double = 1.0
    var liveActivityEnabled: Bool = true
    var notificationsEnabled: Bool = true
}

struct AppData: Codable {
    var notes: [NoteItem] = []
    var customDays: [CustomDay] = []
    var settings: AppSettings = AppSettings()
    /// yyyy-MM-dd -> 当天已点掉的条目 ID
    var seen: [String: [String]] = [:]
    /// 已标记「准备好了」的节日 key
    var prepared: [String] = []
    var didSeedDemo: Bool = false
}

extension AppData {
    static func makeFirstLaunch() -> AppData {
        var data = AppData()
        let now = Date()
        data.notes = [
            NoteItem(text: "她说想去城南新开的那家云南菜，一直没订到位子",
                     category: .mention, createdAt: now.addingTimeInterval(-3 * 86400),
                     dailyReview: true, note: "刷点评的时候随口提了一句", demo: true),
            NoteItem(text: "答应她下周六陪她回趟娘家，别又排了加班",
                     category: .promise, createdAt: now.addingTimeInterval(-86400),
                     dueAt: Calendar.current.date(byAdding: .day, value: 9, to: now),
                     leadDays: 3, dailyReview: true, demo: true),
            NoteItem(text: "她提过想要降噪耳机，说通勤地铁太吵",
                     category: .want, createdAt: now.addingTimeInterval(-5 * 86400),
                     dailyReview: true, demo: true)
        ]
        data.didSeedDemo = true
        return data
    }
}

/// 运行时的一次节日（内置 + 自定义合并后）
struct FestivalOccurrence: Identifiable, Hashable {
    var id: String
    var name: String
    var date: Date
    var emoji: String
    var tier: Int
    var hint: String
    var tags: [String]
}
