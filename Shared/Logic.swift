import Foundation

enum DanmakuLogic {

    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return c
    }()

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func dayKey(_ date: Date = Date()) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    /// to - from，按自然日计算
    static func days(from: Date, to: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDay(from), to: startOfDay(to)).day ?? 0
    }

    /// 考虑重复规则后的下一次发生日期
    static func nextDue(_ note: NoteItem, now: Date = Date()) -> Date? {
        guard let due = note.dueAt else { return nil }
        guard note.repeatRule != .none else { return due }
        let todayStart = startOfDay(now)
        var d = due
        var guardCount = 0
        while d < todayStart && guardCount < 500 {
            let component: Calendar.Component
            let value: Int
            switch note.repeatRule {
            case .daily:   component = .day;   value = 1
            case .weekly:  component = .day;   value = 7
            case .monthly: component = .month; value = 1
            case .yearly:  component = .year;  value = 1
            case .none:    return d
            }
            guard let next = calendar.date(byAdding: component, value: value, to: d) else { break }
            d = next
            guardCount += 1
        }
        return d
    }

    static func isUrgent(_ note: NoteItem, now: Date = Date()) -> Bool {
        guard !note.done, let nd = nextDue(note, now: now) else { return false }
        return days(from: now, to: nd) <= note.leadDays
    }

    /// 今天还需要「点一下才算看到」的条目
    static func pending(_ data: AppData, now: Date = Date()) -> [NoteItem] {
        let seenToday = Set(data.seen[dayKey(now)] ?? [])
        return data.notes.filter { note in
            if note.done { return false }
            if let snooze = note.snoozeUntil, snooze > now { return false }
            if seenToday.contains(note.id) { return false }
            if note.dailyReview { return true }
            guard let nd = nextDue(note, now: now) else { return false }
            return days(from: now, to: nd) <= note.leadDays
        }
        .sorted { a, b in
            let ua = isUrgent(a, now: now) ? 0 : 1
            let ub = isUrgent(b, now: now) ? 0 : 1
            if ua != ub { return ua < ub }
            let da = nextDue(a, now: now) ?? .distantFuture
            let db = nextDue(b, now: now) ?? .distantFuture
            if da != db { return da < db }
            return a.createdAt < b.createdAt
        }
    }

    /// 未完成的、且进入提醒窗口内的条目（含已读，用于计数）
    static func outstanding(_ data: AppData) -> [NoteItem] {
        data.notes.filter { !$0.done }
    }

    // MARK: - 节日

    static func occurrences(_ data: AppData, now: Date = Date()) -> [FestivalOccurrence] {
        let todayStart = startOfDay(now)
        var list: [FestivalOccurrence] = builtInFestivalSeeds.compactMap { seed in
            guard let d = seed.date, d >= todayStart else { return nil }
            return FestivalOccurrence(id: seed.id + "-" + seed.dateString,
                                      name: seed.name, date: d, emoji: seed.emoji,
                                      tier: seed.tier, hint: seed.hint, tags: seed.tags)
        }

        let year = calendar.component(.year, from: now)
        for custom in data.customDays {
            let years = custom.yearly ? [year, year + 1, year + 2] : [year]
            for y in years {
                var c = DateComponents()
                c.calendar = calendar
                c.timeZone = calendar.timeZone
                c.year = y
                c.month = custom.month
                c.day = custom.day
                guard let d = c.date, d >= todayStart else { continue }
                list.append(FestivalOccurrence(
                    id: "custom-" + custom.id + "-" + String(format: "%04d", y),
                    name: custom.name, date: d, emoji: custom.emoji,
                    tier: 1, hint: custom.hint.isEmpty ? "这个日子，提前准备就对了" : custom.hint,
                    tags: ["走心", "浪漫", "仪式感", "陪伴"]))
            }
        }
        return list.sorted { $0.date < $1.date }
    }

    static func nextFestival(_ data: AppData, now: Date = Date()) -> FestivalOccurrence? {
        let all = occurrences(data, now: now)
        return all.first { !data.prepared.contains($0.id) } ?? all.first
    }

    static func festivalDateText(_ date: Date) -> String {
        let c = calendar.dateComponents([.month, .day, .weekday], from: date)
        let week = ["日", "一", "二", "三", "四", "五", "六"]
        let w = week[(c.weekday ?? 1) - 1]
        return "\(c.month ?? 1)月\(c.day ?? 1)日 周\(w)"
    }
}
