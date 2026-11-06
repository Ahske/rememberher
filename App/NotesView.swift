import SwiftUI

struct NotesView: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: Filter = .undone
    @State private var search = ""
    @State private var editing: NoteItem?

    enum Filter: String, CaseIterable, Identifiable {
        case undone, all, done
        var id: String { rawValue }
        var label: String {
            switch self {
            case .undone: return "未完成"
            case .all: return "全部"
            case .done: return "已完成"
            }
        }
    }

    private var visible: [NoteItem] {
        store.data.notes
            .filter { note in
                switch filter {
                case .undone: return !note.done
                case .all: return true
                case .done: return note.done
                }
            }
            .filter { note in
                search.isEmpty || (note.text + note.note).localizedCaseInsensitiveContains(search)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("筛选", selection: $filter) {
                        ForEach(Filter.allCases) { f in Text(f.label).tag(f) }
                    }
                    .pickerStyle(.segmented)
                }

                ForEach(visible) { note in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(note.category.emoji + " " + note.category.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.rhAccent)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(.rhSoft, in: Capsule())
                            Spacer()
                            Text(note.createdAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(note.text)
                            .font(.body.weight(.medium))
                            .strikethrough(note.done)
                            .foregroundStyle(note.done ? .secondary : .primary)
                        if !note.note.isEmpty {
                            Text(note.note).font(.caption).foregroundStyle(.secondary)
                        }
                        HStack {
                            if let due = DanmakuLogic.nextDue(note) {
                                Label(DanmakuLogic.festivalDateText(due), systemImage: "clock")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button {
                                store.toggleDone(note.id)
                            } label: {
                                Image(systemName: note.done ? "arrow.counterclockwise" : "checkmark.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .onTapGesture { editing = note }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { store.delete(note.id) } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }

                if visible.isEmpty {
                    VStack(spacing: 10) {
                        Text("📝").font(.largeTitle)
                        Text("这里还空着。点右上角 ＋，把她今天说的那句记下来。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .searchable(text: $search, prompt: "搜一下她说过的…")
            .navigationTitle("她说过的话")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.showAddNote = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $editing) { note in
                AddNoteView(editing: note)
            }
        }
    }
}

// MARK: - 记一句 / 改一句

struct AddNoteView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var editing: NoteItem? = nil

    @State private var text = ""
    @State private var category: NoteCategory = .mention
    @State private var hasDue = false
    @State private var dueAt = Date()
    @State private var leadDays = 1
    @State private var repeatRule: RepeatRule = .none
    @State private var dailyReview = true
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 92)
                } header: {
                    Text("她的原话 / 这件事")
                } footer: {
                    Text("原话记下来就好。到时间之前，它会自己浮出来提醒你。")
                }

                Section("算哪一类") {
                    Picker("分类", selection: $category) {
                        ForEach(NoteCategory.allCases) { c in
                            Text(c.emoji + " " + c.label).tag(c)
                        }
                    }
                }

                Section("什么时候提醒") {
                    Toggle("有具体日期", isOn: $hasDue)
                    if hasDue {
                        DatePicker("日期", selection: $dueAt, displayedComponents: .date)
                        Stepper("提前 \(leadDays) 天", value: $leadDays, in: 0...14)
                        Picker("重复", selection: $repeatRule) {
                            ForEach(RepeatRule.allCases) { r in Text(r.label).tag(r) }
                        }
                    }
                    Toggle("每天轻轻浮现（不是闹钟）", isOn: $dailyReview)
                }

                Section("当时的上下文") {
                    TextField("可不填，例：她刷手机时随口说的", text: $note)
                }
            }
            .navigationTitle(editing == nil ? "记一句" : "改一下")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("记下来") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadEditing)
        }
    }

    private func loadEditing() {
        guard let e = editing else { return }
        text = e.text
        category = e.category
        hasDue = e.dueAt != nil
        dueAt = e.dueAt ?? Date()
        leadDays = e.leadDays
        repeatRule = e.repeatRule
        dailyReview = e.dailyReview
        note = e.note
    }

    private func save() {
        var item = editing ?? NoteItem()
        item.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        item.category = category
        item.dueAt = hasDue ? dueAt : nil
        item.leadDays = leadDays
        item.repeatRule = hasDue ? repeatRule : .none
        item.dailyReview = dailyReview
        item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if editing == nil {
            store.addNote(item)
        } else {
            store.updateNote(item)
        }
        dismiss()
    }
}
