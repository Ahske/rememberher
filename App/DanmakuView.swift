import SwiftUI

// MARK: - 真正连续滚动的原生弹幕

struct DanmakuView: View {
    @EnvironmentObject var store: AppStore
    @State private var actedNote: NoteItem?

    private var pending: [NoteItem] { DanmakuLogic.pending(store.data) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("慢慢飘，不催你")
                        .font(.system(size: 27, weight: .bold))
                    Text("不响、不震、不弹闹钟。只是安静地飘过去，点一下才算看到。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("还有 \(pending.count) 条没点")
                        .font(.caption.bold())
                        .foregroundStyle(.rhAccent)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(.rhSoft, in: Capsule())
                    Spacer()
                    Button("再飘一遍") {
                        store.data.seen[DanmakuLogic.dayKey()] = []
                        for i in store.data.notes.indices { store.data.notes[i].snoozeUntil = nil }
                        store.commit()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.rhAccent)
                }

                if pending.isEmpty {
                    Spacer(minLength: 20)
                    VStack(spacing: 12) {
                        Text("🍃").font(.system(size: 46))
                        Text("今天都看到了").font(.title3.bold())
                        Text("她说的，你没落下。\n明天这个时间，它们还会轻轻回来。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("想再看一遍") {
                            store.data.seen[DanmakuLogic.dayKey()] = []
                            store.commit()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.rhAccent)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer(minLength: 20)
                } else {
                    DanmakuStage(notes: Array(pending.prefix(8)),
                                 speed: store.data.settings.danmakuSpeed) { note in
                        actedNote = note
                    }
                    .frame(height: 400)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.55))
                    )
                    .clipped()

                    Text("没点过的会一直飘回来，不会自己消失。\n点开一条，选「知道了」今天才不再出现；明天它会重新回来。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                }
            }
            .padding()
            .background(Color.rhBackground.ignoresSafeArea())
            .navigationTitle("弹幕")
            .sheet(item: $actedNote) { note in
                DanmakuActionSheet(note: note)
            }
        }
    }
}

struct DanmakuStage: View {
    let notes: [NoteItem]
    let speed: Double
    let onTap: (NoteItem) -> Void

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                ZStack(alignment: .topLeading) {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { pair in
                        pill(at: pair.offset, note: pair.element,
                             width: geo.size.width,
                             time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
    }

    private func pill(at index: Int, note: NoteItem, width: CGFloat, time: TimeInterval) -> some View {
        let travel = width + 420
        let period = Double(travel) / max(20.0, speed * 55.0)
        let phase = Double(index) * 0.31
        let progress = (time / period + phase).truncatingRemainder(dividingBy: 1.0)
        let x = width + 30 - CGFloat(progress) * CGFloat(travel + 60)
        return DanmakuPill(note: note, urgent: DanmakuLogic.isUrgent(note))
            .fixedSize()
            .offset(x: x, y: CGFloat(index % 4) * 72 + 16)
            .onTapGesture { onTap(note) }
    }
}

struct DanmakuPill: View {
    let note: NoteItem
    var urgent: Bool = false

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(urgent ? Color.red : Color.rhAccent)
                .frame(width: 7, height: 7)
            Text(note.text)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
            Text(note.category.label + (urgent ? " · 快到了" : ""))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.rhAccent.opacity(0.18), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 点开之后：必须选一个动作才取消

struct DanmakuActionSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let note: NoteItem

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 38, height: 4)
                .padding(.top, 6)

            Text("「\(note.text)」")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            VStack(spacing: 4) {
                Text(note.category.emoji + " " + note.category.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let due = DanmakuLogic.nextDue(note) {
                    Text(DanmakuLogic.festivalDateText(due))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !note.note.isEmpty {
                    Text(note.note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            VStack(spacing: 10) {
                Button {
                    store.markSeen(note.id)
                    dismiss()
                } label: {
                    Text("知道了，今天不再出现")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.rhAccent)

                Button {
                    store.snooze(note.id)
                    dismiss()
                } label: {
                    Text("1 小时后再提醒我")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)

                Button {
                    store.toggleDone(note.id)
                    dismiss()
                } label: {
                    Text("已经办好了 ✓")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }

            Text("直接关掉＝还没看到，它会继续飘回来。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .presentationDetents([.medium])
    }
}
