import AppIntents
import SwiftUI
import WidgetKit

// MARK: - 时间线：每 6 分钟换一条没看过的话
// iOS 小组件只给静态快照，不能连续滚动动画，所以用「轮播」实现常驻弹幕。

struct DanmakuEntry: TimelineEntry {
    let date: Date
    let pendingCount: Int
    let notes: [NoteItem]
    let festivalName: String
    let festivalDays: Int
    let festivalEmoji: String
    let groupAvailable: Bool

    static let sample = DanmakuEntry(
        date: Date(), pendingCount: 3,
        notes: [
            NoteItem(text: "她说想去城南新开的那家云南菜", category: .mention),
            NoteItem(text: "答应她下周六陪她回趟娘家", category: .promise),
            NoteItem(text: "她提过想要降噪耳机", category: .want)
        ],
        festivalName: "双十一", festivalDays: 7, festivalEmoji: "🛍", groupAvailable: true
    )
}

struct DanmakuProvider: TimelineProvider {

    func placeholder(in context: Context) -> DanmakuEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (DanmakuEntry) -> Void) {
        completion(make(at: Date(), rotate: 0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DanmakuEntry>) -> Void) {
        let now = Date()
        var entries: [DanmakuEntry] = []
        for i in 0..<16 {
            let date = now.addingTimeInterval(Double(i) * 6 * 60)
            entries.append(make(at: date, rotate: i))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func make(at date: Date, rotate: Int) -> DanmakuEntry {
        let data = SharedStore.shared.load()
        let pending = DanmakuLogic.pending(data, now: date)
        var shown: [NoteItem] = []
        if !pending.isEmpty {
            let offset = rotate % pending.count
            let rotated = Array(pending[offset...]) + Array(pending[..<offset])
            shown = Array(rotated.prefix(3))
        }
        let fest = DanmakuLogic.nextFestival(data, now: date)
        return DanmakuEntry(
            date: date,
            pendingCount: pending.count,
            notes: shown,
            festivalName: fest?.name ?? "",
            festivalDays: fest.map { DanmakuLogic.days(from: date, to: $0.date) } ?? -1,
            festivalEmoji: fest?.emoji ?? "🎈",
            groupAvailable: SharedStore.shared.isGroupAvailable
        )
    }
}

// MARK: - Widget

struct DanmakuWidget: Widget {
    let kind = "DanmakuWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DanmakuProvider()) { entry in
            DanmakuWidgetView(entry: entry)
        }
        .configurationDisplayName("记得 · 她说的话")
        .description("没点过的会一直在，点 ✓ 今天才不再出现。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct DanmakuWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DanmakuEntry

    var body: some View {
        Group {
            if !entry.groupAvailable {
                NotSharedView()
            } else {
                switch family {
                case .systemSmall:  SmallWidget(entry: entry)
                case .systemLarge:  LargeWidget(entry: entry)
                default:           MediumWidget(entry: entry)
                }
            }
        }
        .containerBackground(for: .widget) { Color.rhBackground }
        .widgetURL(URL(string: "rememberher://danmaku"))
    }
}

// MARK: - 小尺寸

struct SmallWidget: View {
    let entry: DanmakuEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("记得").font(.caption.bold()).foregroundStyle(.rhAccent)
                Spacer()
                Text("\(entry.pendingCount)").font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule().fill(.rhAccent))
            }
            if let first = entry.notes.first {
                Text("「\(first.text)」")
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)
                Text(first.category.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Spacer(minLength: 4)
                Text("🍃").font(.title2)
                Text("今天都看到了").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            HStack {
                Text("还有 \(entry.pendingCount) 句没看")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if let first = entry.notes.first {
                    Button(intent: MarkSeenIntent(noteID: first.id)) {
                        Image(systemName: "checkmark.circle.fill").font(.title3)
                    }
                    .buttonStyle(.plain)
                    .tint(.rhAccent)
                }
            }
        }
        .padding(4)
    }
}

// MARK: - 中尺寸

struct MediumWidget: View {
    let entry: DanmakuEntry

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("记得 · 她说的话").font(.caption.bold()).foregroundStyle(.rhAccent)
                    Spacer()
                }
                if let first = entry.notes.first {
                    Text("「\(first.text)」")
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                    Text(first.category.emoji + " " + first.category.label)
                        .font(.caption2).foregroundStyle(.secondary)
                } else {
                    Text("🍃 今天都看到了")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                HStack {
                    Text("还有 \(entry.pendingCount) 句没看")
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    if let first = entry.notes.first {
                        Button(intent: MarkSeenIntent(noteID: first.id)) {
                            Label("看到了", systemImage: "checkmark.circle.fill")
                                .font(.caption2.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .tint(.rhAccent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .center, spacing: 4) {
                Text(entry.festivalEmoji).font(.title2)
                Text(entry.festivalName)
                    .font(.caption.bold())
                    .lineLimit(1)
                if entry.festivalDays >= 0 {
                    Text(entry.festivalDays == 0 ? "今天" : "\(entry.festivalDays)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.rhAccent)
                    Text("天后").font(.caption2).foregroundStyle(.secondary)
                }
                Text("该准备了")
                    .font(.caption2)
                    .foregroundStyle(entry.festivalDays <= 5 ? .rhAccent : .secondary)
            }
            .frame(width: 78)
        }
        .padding(4)
    }
}

// MARK: - 大尺寸

struct LargeWidget: View {
    let entry: DanmakuEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("记得 · 她说的话").font(.caption.bold()).foregroundStyle(.rhAccent)
                Spacer()
                Text("还有 \(entry.pendingCount) 句没看")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            if entry.notes.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Text("🍃").font(.title)
                        Text("今天都看到了，她说的你没落下")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.notes) { note in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(DanmakuLogic.isUrgent(note) ? Color.red : Color.rhAccent)
                            .frame(width: 7, height: 7)
                            .padding(.top, 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(note.text)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(2)
                            Text(note.category.label)
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 4)
                        Button(intent: MarkSeenIntent(noteID: note.id)) {
                            Image(systemName: "checkmark.circle")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .tint(.rhAccent)
                    }
                    Divider()
                }
                Spacer(minLength: 0)
            }

            HStack {
                Text(entry.festivalEmoji + " " + entry.festivalName)
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                if entry.festivalDays >= 0 {
                    Text(entry.festivalDays == 0 ? "就是今天" : "\(entry.festivalDays) 天后")
                        .font(.caption.bold()).foregroundStyle(.rhAccent)
                }
            }
        }
        .padding(4)
    }
}

// MARK: - 侧载时 App Group 不可用的提示态

struct NotSharedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("小组件还没连上数据")
                .font(.subheadline.bold())
            Text("请在 Xcode 里为两个 Target 开启同一个 App Group，或用开发者账号重新签名。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }
}
