import ActivityKit
import AppIntents
import Foundation
import WidgetKit

/// 灵动岛 / 锁屏实时活动的开关与刷新
@MainActor
final class LiveActivityController {

    private static func makeContent() -> ActivityContent<DanmakuAttributes.ContentState> {
        let data = SharedStore.shared.load()
        let state = DanmakuAttributes.ContentState.make(from: data)
        let staleDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date())
        return ActivityContent(state: state, staleDate: staleDate, relevanceScore: 100)
    }

    static func isEnabled() -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
        return SharedStore.shared.load().settings.liveActivityEnabled
    }

    static func startIfEnabled() async {
        guard isEnabled() else { return }
        await start()
    }

    static func start() async {
        guard Activity<DanmakuAttributes>.activities.isEmpty else {
            await updateIfActive()
            return
        }
        do {
            _ = try Activity<DanmakuAttributes>.request(
                attributes: DanmakuAttributes(startedAt: Date()),
                content: makeContent(),
                pushType: nil
            )
        } catch {
            print("[记得] 实时活动启动失败: \(error)")
        }
    }

    static func updateIfActive() async {
        guard let activity = Activity<DanmakuAttributes>.activities.first else { return }
        await activity.update(makeContent())
    }

    static func stop() async {
        for activity in Activity<DanmakuAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// 系统最长保留约 12 小时，快捷指令每天调一次即可长期常驻
    static func refreshOrStart() async {
        guard isEnabled() else { return }
        if Activity<DanmakuAttributes>.activities.isEmpty {
            await start()
        } else {
            await updateIfActive()
        }
    }

    static func refreshOrStartFromIntent() async {
        await refreshOrStart()
    }
}

// MARK: - 快捷指令

struct RefreshDanmakuIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新记得弹幕"

    func perform() async throws -> some IntentResult {
        await LiveActivityController.refreshOrStartFromIntent()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct RememberHerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: RefreshDanmakuIntent(),
                    phrases: [],
                    shortTitle: "刷新弹幕",
                    systemImageName: "text.bubble.fill")
    }
}
