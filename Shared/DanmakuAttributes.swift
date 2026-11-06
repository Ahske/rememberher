import ActivityKit
import Foundation

/// 灵动岛 / 锁屏实时活动的属性与可变状态
struct DanmakuAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var pendingCount: Int
        var topText: String
        var topCategory: String
        var topNoteID: String
        var urgent: Bool
        var festivalName: String
        var festivalDays: Int
    }

    var startedAt: Date
}

extension DanmakuAttributes.ContentState {
    static func make(from data: AppData, now: Date = Date()) -> DanmakuAttributes.ContentState {
        let pending = DanmakuLogic.pending(data, now: now)
        let top = pending.first
        let fest = DanmakuLogic.nextFestival(data, now: now)
        return DanmakuAttributes.ContentState(
            pendingCount: pending.count,
            topText: top?.text ?? "今天都看到了，她说的你没落下",
            topCategory: top?.category.label ?? "",
            topNoteID: top?.id ?? "",
            urgent: top.map { DanmakuLogic.isUrgent($0, now: now) } ?? false,
            festivalName: fest?.name ?? "",
            festivalDays: fest.map { DanmakuLogic.days(from: now, to: $0.date) } ?? -1
        )
    }

    static let placeholder = DanmakuAttributes.ContentState(
        pendingCount: 3,
        topText: "她说想去城南新开的那家云南菜",
        topCategory: "随口一提",
        topNoteID: "",
        urgent: false,
        festivalName: "双十一",
        festivalDays: 7
    )
}
