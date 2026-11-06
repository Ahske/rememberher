import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        TabView(selection: $store.selectedTab) {
            TodayView()
                .tabItem { Label("今天", systemImage: "sun.max") }
                .tag(AppTab.today)
            DanmakuView()
                .tabItem { Label("弹幕", systemImage: "text.bubble") }
                .tag(AppTab.danmaku)
            NotesView()
                .tabItem { Label("记录", systemImage: "list.bullet") }
                .tag(AppTab.notes)
            FestivalsView()
                .tabItem { Label("节日", systemImage: "calendar") }
                .tag(AppTab.festivals)
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(.rhAccent)
        .sheet(isPresented: $store.showAddNote) { AddNoteView() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.reload()
                Task { await LiveActivityController.updateIfActive() }
            }
        }
    }
}

// MARK: - 今天

struct TodayView: View {
    @EnvironmentObject var store: AppStore
    @State private var giftFest: FestivalOccurrence?

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 6 { return "还没睡" }
        if h < 11 { return "早上好" }
        if h < 14 { return "中午好" }
        if h < 18 { return "下午好" }
        return "晚上好"
    }

    /// 每天轮换起点，让久远的记录也有机会被想起来
    private var recall: [NoteItem] {
        let pending = DanmakuLogic.pending(store.data)
        guard !pending.isEmpty else { return [] }
        let day = Int(Date().timeIntervalSince1970 / 86400)
        let offset = day % pending.count
        let rotated = Array(pending[offset...]) + Array(pending[..<offset])
        return Array(rotated.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(DanmakuLogic.festivalDateText(Date()))
                            .font(.caption.bold())
                            .foregroundStyle(.rhAccent)
                        Text("\(greeting)，别让忙变成忘")
                            .font(.system(size: 28, weight: .bold))
                        Text("这里只放两件事：快要到的日子，和她说过的话。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let fest = DanmakuLogic.nextFestival(store.data) {
                        festivalCard(fest)
                    }

                    let pendingCount = DanmakuLogic.pending(store.data).count
                    if pendingCount > 0 {
                        Button {
                            store.selectedTab = .danmaku
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(pendingCount)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(.rhAccent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("句她说过的话，今天还没看")
                                        .font(.subheadline.weight(.semibold))
                                    Text("不点一下，明天还会在")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(.rhSoft, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("她说过的话 · 今天回放")
                        .font(.headline)
                        .padding(.top, 4)

                    if recall.isEmpty {
                        VStack(spacing: 8) {
                            Text("🍃").font(.largeTitle)
                            Text("今天都看到了。她说的，你没落下。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(28)
                        .background(.white, in: RoundedRectangle(cornerRadius: 20))
                    } else {
                        VStack(spacing: 0) {
                            ForEach(recall) { note in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("「\(note.text)」")
                                        .font(.body.weight(.medium))
                                    HStack(spacing: 8) {
                                        Text(note.category.emoji + " " + note.category.label)
                                            .font(.caption2)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(.rhSoft, in: Capsule())
                                        Text(note.createdAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    HStack {
                                        Spacer()
                                        Button("看到了") { store.markSeen(note.id) }
                                            .font(.caption.weight(.semibold))
                                            .buttonStyle(.bordered)
                                            .tint(.rhAccent)
                                    }
                                }
                                .padding(.vertical, 14)
                                Divider()
                            }
                            Text("每天换一批，久一点的话也不会被忘掉")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 12)
                        }
                        .padding(.horizontal, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding()
            }
            .background(Color.rhBackground.ignoresSafeArea())
            .navigationTitle("记得")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.showAddNote = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $giftFest) { fest in
                GiftPanelView(festival: fest)
            }
        }
    }

    private func festivalCard(_ fest: FestivalOccurrence) -> some View {
        let days = DanmakuLogic.days(from: Date(), to: fest.date)
        let soon = days <= store.data.settings.leadDays
        return VStack(alignment: .leading, spacing: 10) {
            Text(soon ? "该准备了 · 提前 \(store.data.settings.leadDays) 天" : "下一个日子")
                .font(.caption.bold())
                .opacity(0.9)
            Text("\(fest.emoji) \(fest.name)")
                .font(.system(size: 25, weight: .bold))
            Text(DanmakuLogic.festivalDateText(fest.date))
                .font(.caption)
                .opacity(0.9)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(days == 0 ? "今天" : "\(days)")
                    .font(.system(size: 44, weight: .bold))
                if days != 0 { Text("天后").font(.subheadline) }
            }
            Text(fest.hint)
                .font(.subheadline)
                .opacity(0.95)
            HStack(spacing: 10) {
                Button("看礼物推荐") { giftFest = fest }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.rhAccent)
                Button("全部节日") { store.selectedTab = .festivals }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color(red: 0.91, green: 0.65, blue: 0.60), .rhAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .rhAccent.opacity(0.22), radius: 16, x: 0, y: 8)
    }
}
