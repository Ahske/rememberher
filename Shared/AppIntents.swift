import AppIntents
import Foundation
import WidgetKit

/// 桌面小组件 / 灵动岛上的「✓」按钮 —— 点一下，今天才不再出现
struct MarkSeenIntent: AppIntent {
    static var title: LocalizedStringResource = "标记为已看到"

    @Parameter(title: "条目 ID")
    var noteID: String

    init() {}
    init(noteID: String) { self.noteID = noteID }

    func perform() async throws -> some IntentResult {
        SharedStore.shared.markSeen(id: noteID)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// 灵动岛展开视图里的「已经办好了」
struct MarkDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "已经办好了"

    @Parameter(title: "条目 ID")
    var noteID: String

    init() {}
    init(noteID: String) { self.noteID = noteID }

    func perform() async throws -> some IntentResult {
        SharedStore.shared.markDone(id: noteID)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// 「1 小时后再提醒」
struct SnoozeIntent: AppIntent {
    static var title: LocalizedStringResource = "1 小时后再提醒"

    @Parameter(title: "条目 ID")
    var noteID: String

    init() {}
    init(noteID: String) { self.noteID = noteID }

    func perform() async throws -> some IntentResult {
        SharedStore.shared.snooze(id: noteID, hours: 1)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// 注意：快捷指令用的 RefreshDanmakuIntent 依赖 ActivityKit 管理类，
// 只放在主 App target（见 App/RefreshIntent.swift），避免小组件扩展重复注册。
