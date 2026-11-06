import Foundation

/// 主 App / 小组件 / 灵动岛 共用的唯一数据源。
/// 正式签名时走 App Group；若容器不可用（例如某些侧载场景），自动退回 App 沙盒，
/// 此时小组件读不到主 App 数据，会显示提示态。
final class SharedStore {

    static let shared = SharedStore()

    /// ⚠️ 改成你自己的 App Group 时，请同时改两个 .entitlements 文件
    static let groupID = "group.com.rememberher.shared"

    private let fileName = "appdata.json"
    private let lock = NSLock()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    var isGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.groupID) != nil
    }

    private var fileURL: URL? {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.groupID) {
            return container.appendingPathComponent(fileName)
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent(fileName)
    }

    func load() -> AppData {
        lock.lock()
        defer { lock.unlock() }
        guard let url = fileURL,
              let raw = try? Data(contentsOf: url),
              let data = try? decoder.decode(AppData.self, from: raw) else {
            return AppData.makeFirstLaunch()
        }
        return data
    }

    func save(_ data: AppData) {
        lock.lock()
        defer { lock.unlock() }
        guard let url = fileURL, let raw = try? encoder.encode(data) else { return }
        try? raw.write(to: url, options: .atomic)
    }

    // MARK: - 供 App Intent 调用（不要在这里再加锁，load/save 各自已加锁）

    func markSeen(id: String, now: Date = Date()) {
        var data = load()
        let key = DanmakuLogic.dayKey(now)
        var arr = data.seen[key] ?? []
        if !arr.contains(id) { arr.append(id) }
        data.seen[key] = arr
        save(data)
    }

    func markDone(id: String) {
        var data = load()
        if let i = data.notes.firstIndex(where: { $0.id == id }) {
            data.notes[i].done = true
        }
        save(data)
    }

    func snooze(id: String, hours: Double = 1, now: Date = Date()) {
        var data = load()
        if let i = data.notes.firstIndex(where: { $0.id == id }) {
            data.notes[i].snoozeUntil = now.addingTimeInterval(hours * 3600)
        }
        save(data)
    }
}
