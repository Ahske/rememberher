import SwiftUI
import UIKit

struct FestivalsView: View {
    @EnvironmentObject var store: AppStore
    @State private var expandedID: String?
    @State private var showAddCustom = false
    @State private var giftFest: FestivalOccurrence?

    private var list: [FestivalOccurrence] {
        Array(DanmakuLogic.occurrences(store.data).prefix(60))
    }

    private func gifts(for fest: FestivalOccurrence) -> [GiftItem] {
        let tags = Set(fest.tags)
        return builtInGifts
            .map { (gift: $0, score: Set($0.tags).intersection(tags).count) }
            .filter { $0.score > 0 }
            .sorted { a, b in
                if a.score != b.score { return a.score > b.score }
                return a.gift.price < b.gift.price
            }
            .map { $0.gift }
    }

    private var herOwnWishes: [NoteItem] {
        store.data.notes.filter { !$0.done && ($0.category == .want || $0.category == .like) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Button {
                            showAddCustom = true
                        } label: {
                            Label("加个日子", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(.rhSoft, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.rhAccent)

                        Button {
                            store.selectedTab = .settings
                        } label: {
                            Label("装到桌面", systemImage: "square.grid.2x2")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }

                    ForEach(list) { fest in
                        let days = DanmakuLogic.days(from: Date(), to: fest.date)
                        let prepared = store.data.prepared.contains(fest.id)
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedID = expandedID == fest.id ? nil : fest.id
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(fest.emoji)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(.rhSoft, in: RoundedRectangle(cornerRadius: 14))
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(fest.name).font(.headline)
                                            if prepared {
                                                Text("已准备").font(.caption2)
                                                    .foregroundStyle(.green)
                                            } else if days <= store.data.settings.leadDays {
                                                Text("该准备了").font(.caption2)
                                                    .foregroundStyle(.rhAccent)
                                            }
                                        }
                                        Text(DanmakuLogic.festivalDateText(fest.date) + " · " + fest.hint)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer(minLength: 4)
                                    VStack(spacing: 0) {
                                        Text(days == 0 ? "今天" : "\(days)")
                                            .font(.title3.bold())
                                            .foregroundStyle(.rhAccent)
                                        if days != 0 { Text("天后").font(.caption2).foregroundStyle(.tertiary) }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.primary)

                            if expandedID == fest.id {
                                Divider()
                                if !herOwnWishes.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("她自己说过的，优先考虑：").font(.caption.bold()).foregroundStyle(.rhAccent)
                                        ForEach(herOwnWishes.prefix(3)) { n in
                                            Text("· " + n.text).font(.caption)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(.rhSoft, in: RoundedRectangle(cornerRadius: 10))
                                }
                                ForEach(Array(gifts(for: fest).prefix(3))) { gift in
                                    HStack(alignment: .top, spacing: 9) {
                                        Text(String(gift.cat.prefix(1)))
                                            .font(.caption.bold())
                                            .foregroundStyle(.rhAccent)
                                            .frame(width: 26, height: 26)
                                            .background(.rhSoft, in: RoundedRectangle(cornerRadius: 8))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(gift.title).font(.subheadline.weight(.medium))
                                            Text(gift.desc).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength: 4)
                                        Text(gift.priceText).font(.caption2).foregroundStyle(.rhAccent)
                                    }
                                    .padding(.vertical, 4)
                                }
                                HStack(spacing: 10) {
                                    Button("更多礼物") { giftFest = fest }
                                        .buttonStyle(.borderedProminent).tint(.rhAccent)
                                    Button(prepared ? "取消已准备" : "标记已准备") {
                                        store.togglePrepared(fest.id)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .font(.caption)
                            }
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                    }
                }
                .padding()
            }
            .background(Color.rhBackground.ignoresSafeArea())
            .navigationTitle("节日与日子")
            .sheet(isPresented: $showAddCustom) { AddCustomDayView() }
            .sheet(item: $giftFest) { GiftPanelView(festival: $0) }
        }
    }
}

// MARK: - 礼物面板

struct GiftPanelView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    let festival: FestivalOccurrence

    @State private var category = "全部"
    private let categories = ["全部", "走心", "实用", "体验", "浪漫", "长辈"]

    private var gifts: [GiftItem] {
        let tags = Set(festival.tags)
        return builtInGifts
            .filter { category == "全部" || $0.cat == category }
            .map { (gift: $0, score: Set($0.tags).intersection(tags).count) }
            .filter { $0.score > 0 }
            .sorted { a, b in
                if a.score != b.score { return a.score > b.score }
                return a.gift.price < b.gift.price
            }
            .prefix(20)
            .map { $0.gift }
    }

    private var herOwnWishes: [NoteItem] {
        store.data.notes.filter { !$0.done && ($0.category == .want || $0.category == .like) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(festival.emoji + " " + festival.name + " · " + DanmakuLogic.festivalDateText(festival.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !herOwnWishes.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("她自己提过的，最不会送错：")
                                .font(.caption.bold()).foregroundStyle(.rhAccent)
                            ForEach(herOwnWishes) { n in Text("· " + n.text).font(.caption) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.rhSoft, in: RoundedRectangle(cornerRadius: 12))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { c in
                                Button(c) { category = c }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 13).padding(.vertical, 7)
                                    .background(category == c ? Color.rhAccent : Color(uiColor: .secondarySystemBackground),
                                                in: Capsule())
                                    .foregroundStyle(category == c ? .white : .secondary)
                            }
                        }
                    }

                    ForEach(gifts) { gift in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(gift.title).font(.subheadline.weight(.semibold))
                            Text(gift.desc).font(.caption).foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                Text(gift.cat).font(.caption2).padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                                Text(gift.priceText).font(.caption2).padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        Divider()
                    }
                }
                .padding()
            }
            .background(Color.rhBackground.ignoresSafeArea())
            .navigationTitle("送什么")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("关上") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 自定义纪念日

struct AddCustomDayView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var month = 1
    @State private var day = 1
    @State private var emoji = "🎂"
    @State private var hint = ""
    @State private var yearly = true

    private let emojis = ["🎂", "💍", "💐", "❤️", "🏡", "👶", "✈️", "🎓"]

    var body: some View {
        NavigationStack {
            Form {
                Section("叫什么") {
                    TextField("例：结婚纪念日 / 她的生日", text: $name)
                }
                Section("哪一天") {
                    Picker("月", selection: $month) {
                        ForEach(1...12, id: \.self) { Text("\($0) 月").tag($0) }
                    }
                    Picker("日", selection: $day) {
                        ForEach(1...31, id: \.self) { Text("\($0) 日").tag($0) }
                    }
                    Toggle("每年重复", isOn: $yearly)
                }
                Section("挑个图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(emojis, id: \.self) { e in
                            Text(e)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(emoji == e ? Color.rhSoft : Color(uiColor: .secondarySystemBackground),
                                            in: RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { emoji = e }
                        }
                    }
                }
                Section("提醒的话") {
                    TextField("可不填，例：订个位子，别又加班", text: $hint)
                }
            }
            .navigationTitle("加一个我们的日子")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("加进去") {
                        let item = CustomDay(name: name.trimmingCharacters(in: .whitespaces),
                                             month: month, day: day, emoji: emoji,
                                             hint: hint, yearly: yearly)
                        store.data.customDays.append(item)
                        store.commit()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
