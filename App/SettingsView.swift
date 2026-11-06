import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showImporter = false
    @State private var importMessage: String?
    @State private var exportURL: URL?
    @State private var liveActivityOn = true

    private var leadBinding: Binding<Int> {
        Binding(get: { store.data.settings.leadDays },
                set: { store.data.settings.leadDays = $0; store.commit() })
    }

    private var speedBinding: Binding<Double> {
        Binding(get: { store.data.settings.danmakuSpeed },
                set: { store.data.settings.danmakuSpeed = $0; store.commit() })
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = store.data.settings.dailyHour
                c.minute = store.data.settings.dailyMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.data.settings.dailyHour = c.hour ?? 20
                store.data.settings.dailyMinute = c.minute ?? 30
                store.commit()
            }
        )
    }

    private var notifyBinding: Binding<Bool> {
        Binding(get: { store.data.settings.notificationsEnabled },
                set: { store.data.settings.notificationsEnabled = $0; store.commit() })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: SharedStore.shared.isGroupAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(SharedStore.shared.isGroupAvailable ? .green : .orange)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(SharedStore.shared.isGroupAvailable ? "小组件数据通道正常" : "小组件读不到主 App 数据")
                                .font(.subheadline.weight(.semibold))
                            Text(SharedStore.shared.isGroupAvailable
                                 ? "主 App、桌面小组件、灵动岛共用同一份记录"
                                 : "多见于免费账号侧载：需要在签名里开启 App Group，详见安装说明")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("灵动岛 / 锁屏实时活动", isOn: $liveActivityOn)
                        .onChange(of: liveActivityOn) { _, on in
                            store.data.settings.liveActivityEnabled = on
                            store.commit()
                            Task {
                                if on { await LiveActivityController.start() }
                                else { await LiveActivityController.stop() }
                            }
                        }

                    Button("立刻刷新一次实时活动") {
                        Task { await LiveActivityController.refreshOrStart() }
                    }
                } header: {
                    Text("常驻显示")
                } footer: {
                    Text("长按桌面 → 左上角 ＋ → 搜索「记得」添加小组件。小组件每几分钟自动换一条没看过的话，点 ✓ 今天才不再出现。灵动岛在 iPhone 14 Pro 及以上常驻，其它机型显示在锁屏。实时活动系统最长保留约 12 小时，用快捷指令每天自动「刷新弹幕」即可长期常驻。")
                }

                Section("提醒") {
                    Picker("节日提前", selection: leadBinding) {
                        Text("4 天").tag(4)
                        Text("5 天").tag(5)
                        Text("7 天").tag(7)
                    }
                    DatePicker("每天浮现时间", selection: timeBinding, displayedComponents: .hourAndMinute)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("弹幕速度：\(String(format: "%.1f", store.data.settings.danmakuSpeed))×")
                            .font(.subheadline)
                        Slider(value: speedBinding, in: 0.6...1.8, step: 0.1)
                    }
                    Toggle("安静通知横幅", isOn: notifyBinding)
                    Button("开启通知权限") {
                        Task {
                            await NotificationManager.shared.setupIfNeeded()
                            store.commit()
                        }
                    }
                    Button("去系统设置改通知") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } footer: {
                    Text("通知只有横幅与通知中心，不设声音、不震动，不是闹钟。节日提前提醒由本机日历触发，不依赖网络。")
                }

                Section("数据") {
                    Button("从网页版导入 JSON") { showImporter = true }
                    Button("导出备份") { exportURL = WebImport.exportURL(store.data) }
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("点这里分享备份文件", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button("清掉示例内容") { store.clearDemo() }
                    Button("刷新桌面小组件") {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } footer: {
                    Text("网页版导出的 JSON 可以直接导入，记录、纪念日、设置都会带过来。数据只存在这台手机，换机前记得导出。")
                }

                Section("关于") {
                    LabeledContent("版本", value: "1.0 原生版")
                    LabeledContent("数据", value: "仅本机，无账号、无上传")
                    Text("iOS 不允许小组件做连续滚动动画，所以桌面版用「时间线轮播」实现弹幕；App 内是真正连续飘动的弹幕。灵动岛与锁屏是系统允许的最接近「常驻桌面」的形态。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .onAppear { liveActivityOn = store.data.settings.liveActivityEnabled }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    if let raw = try? Data(contentsOf: url),
                       let imported = WebImport.convert(raw) {
                        store.replaceAll(imported)
                        importMessage = "导入好了，共 \(imported.notes.count) 条记录、\(imported.customDays.count) 个自定义日子"
                    } else {
                        importMessage = "这个文件读不出来，请选网页版「导出备份」生成的 JSON"
                    }
                case .failure:
                    importMessage = "没能打开这个文件"
                }
            }
            .alert("导入结果",
                   isPresented: Binding(get: { importMessage != nil },
                                       set: { if !$0 { importMessage = nil } })) {
                Button("好") { importMessage = nil }
            } message: {
                Text(importMessage ?? "")
            }
        }
    }
}

// MARK: - 与网页版互导数据

enum WebImport {

    static func convert(_ raw: Data) -> AppData? {
        guard let obj = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any],
              let notes = obj["notes"] as? [[String: Any]] else { return nil }

        var out = AppData()
        out.notes = notes.compactMap { d -> NoteItem? in
            guard let text = d["text"] as? String else { return nil }
            var n = NoteItem()
            n.id = d["id"] as? String ?? UUID().uuidString
            n.text = text
            n.category = NoteCategory(rawValue: d["category"] as? String ?? "mention") ?? .mention
            if let num = d["createdAt"] as? NSNumber {
                n.createdAt = Date(timeIntervalSince1970: num.doubleValue / 1000.0)
            }
            if let s = d["dueAt"] as? String, !s.isEmpty { n.dueAt = day(s) }
            n.leadDays = (d["leadDays"] as? NSNumber)?.intValue ?? 1
            n.repeatRule = RepeatRule(rawValue: d["repeat"] as? String ?? "none") ?? .none
            n.dailyReview = d["dailyReview"] as? Bool ?? true
            n.done = d["done"] as? Bool ?? false
            n.note = d["note"] as? String ?? ""
            n.demo = d["demo"] as? Bool ?? false
            return n
        }

        if let customs = obj["customDays"] as? [[String: Any]] {
            out.customDays = customs.compactMap { d -> CustomDay? in
                guard let name = d["name"] as? String else { return nil }
                return CustomDay(
                    id: d["id"] as? String ?? UUID().uuidString,
                    name: name,
                    month: (d["month"] as? NSNumber)?.intValue ?? 1,
                    day: (d["day"] as? NSNumber)?.intValue ?? 1,
                    emoji: d["emoji"] as? String ?? "🎂",
                    hint: d["hint"] as? String ?? "",
                    yearly: (d["repeat"] as? String) != "once"
                )
            }
        }

        if let s = obj["settings"] as? [String: Any] {
            out.settings.leadDays = (s["leadDays"] as? NSNumber)?.intValue ?? 5
            out.settings.danmakuSpeed = (s["speed"] as? NSNumber)?.doubleValue ?? 1.0
            out.settings.notificationsEnabled = s["notify"] as? Bool ?? true
            if let time = s["dailyTime"] as? String {
                let p = time.split(separator: ":").compactMap { Int($0) }
                if p.count == 2 {
                    out.settings.dailyHour = p[0]
                    out.settings.dailyMinute = p[1]
                }
            }
        }

        if let seen = obj["seen"] as? [String: [String]] { out.seen = seen }
        if let prepared = obj["prepared"] as? [String: Any] {
            out.prepared = Array(prepared.keys)
        }
        out.didSeedDemo = true
        return out
    }

    static func exportURL(_ data: AppData) -> URL? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let raw = try? encoder.encode(data) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rememberher-backup-\(DanmakuLogic.dayKey()).json")
        try? raw.write(to: url, options: .atomic)
        return url
    }

    private static func day(_ s: String) -> Date? {
        let p = s.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        var c = DateComponents()
        c.calendar = DanmakuLogic.calendar
        c.timeZone = DanmakuLogic.calendar.timeZone
        c.year = p[0]; c.month = p[1]; c.day = p[2]; c.hour = 0
        return c.date
    }
}
