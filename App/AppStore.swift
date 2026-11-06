import Foundation
import SwiftUI
import WidgetKit

enum AppTab: String, CaseIterable {
    case today, danmaku, notes, festivals, settings
}

@MainActor
final class AppStore: ObservableObject {
    @Published var data: AppData
    @Published var selectedTab: AppTab = .today
    @Published var showAddNote = false

    init() {
        self.data = SharedStore.shared.load()
    }

    func reload() {
        data = SharedStore.shared.load()
    }

    /// 任何写操作之后统一调用：持久化 + 刷新小组件 + 刷新灵动岛 + 重排通知
    func commit() {
        SharedStore.shared.save(data)
        WidgetCenter.shared.reloadAllTimelines()
        Task { await LiveActivityController.updateIfActive() }
        NotificationManager.shared.scheduleAll(data)
    }

    func addNote(_ note: NoteItem) {
        data.notes.insert(note, at: 0)
        commit()
    }

    func updateNote(_ note: NoteItem) {
        if let i = data.notes.firstIndex(where: { $0.id == note.id }) {
            data.notes[i] = note
            commit()
        }
    }

    func toggleDone(_ id: String) {
        if let i = data.notes.firstIndex(where: { $0.id == id }) {
            data.notes[i].done.toggle()
            commit()
        }
    }

    func delete(_ id: String) {
        data.notes.removeAll { $0.id == id }
        commit()
    }

    func markSeen(_ id: String) {
        let key = DanmakuLogic.dayKey()
        var arr = data.seen[key] ?? []
        if !arr.contains(id) { arr.append(id) }
        data.seen[key] = arr
        commit()
    }

    func snooze(_ id: String, hours: Double = 1) {
        if let i = data.notes.firstIndex(where: { $0.id == id }) {
            data.notes[i].snoozeUntil = Date().addingTimeInterval(hours * 3600)
            commit()
        }
    }

    func togglePrepared(_ id: String) {
        if let i = data.prepared.firstIndex(of: id) {
            data.prepared.remove(at: i)
        } else {
            data.prepared.append(id)
        }
        commit()
    }

    func clearDemo() {
        data.notes.removeAll { $0.demo }
        commit()
    }

    func replaceAll(_ newData: AppData) {
        data = newData
        commit()
    }
}
