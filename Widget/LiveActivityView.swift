import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// 灵动岛 / 锁屏实时活动：系统允许的最接近「常驻桌面」的形态
struct DanmakuLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DanmakuAttributes.self) { context in
            LockScreenLiveActivityView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 5) {
                        Image(systemName: "text.bubble.fill")
                        Text("记得")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.rhAccent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("还有 \(context.state.pendingCount) 句")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    if !context.state.festivalName.isEmpty && context.state.festivalDays >= 0 {
                        Text("\(context.state.festivalName) · \(context.state.festivalDays) 天后")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(.rhAccent)
            } compactTrailing: {
                Text("\(context.state.pendingCount)")
                    .font(.caption.bold())
                    .foregroundStyle(.rhAccent)
            } minimal: {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(.rhAccent)
            }
            .keylineTint(.rhAccent)
        }
    }
}

// MARK: - 灵动岛展开态

struct ExpandedBottomView: View {
    let state: DanmakuAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(state.topText)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)

            HStack(spacing: 8) {
                if !state.topNoteID.isEmpty {
                    Button(intent: MarkSeenIntent(noteID: state.topNoteID)) {
                        Label("知道了", systemImage: "checkmark")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .tint(.rhAccent)

                    Button(intent: SnoozeIntent(noteID: state.topNoteID)) {
                        Label("稍后", systemImage: "clock")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)

                    Button(intent: MarkDoneIntent(noteID: state.topNoteID)) {
                        Label("办好了", systemImage: "checkmark.circle")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                } else {
                    Text("今天都看到了 🍃")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - 锁屏横幅（所有支持实时活动的机型都有）

struct LockScreenLiveActivityView: View {
    let state: DanmakuAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label("记得", systemImage: "text.bubble.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.rhAccent)
                Spacer()
                Text("还有 \(state.pendingCount) 句没看")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(state.topText)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)

            HStack(spacing: 8) {
                if !state.festivalName.isEmpty && state.festivalDays >= 0 {
                    Text("\(state.festivalName) · \(state.festivalDays) 天后")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !state.topNoteID.isEmpty {
                    Button(intent: MarkSeenIntent(noteID: state.topNoteID)) {
                        Label("看到了", systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .tint(.rhAccent)
                }
            }
        }
        .padding(14)
        .activityBackgroundTint(Color.rhSoft.opacity(0.75))
        .activitySystemActionForegroundColor(.rhAccent)
        .widgetURL(URL(string: "rememberher://danmaku"))
    }
}

// MARK: - Widget Extension 入口

@main
struct RememberHerWidgetBundle: WidgetBundle {
    var body: some Widget {
        DanmakuWidget()
        DanmakuLiveActivity()
    }
}
