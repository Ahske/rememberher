import SwiftUI
import UIKit
import UserNotifications

@main
struct RememberHerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onOpenURL { url in
                    guard url.scheme == "rememberher" else { return }
                    switch url.host {
                    case "danmaku": store.selectedTab = .danmaku
                    case "add":     store.showAddNote = true
                    case "festivals": store.selectedTab = .festivals
                    default: break
                    }
                }
                .task {
                    await NotificationManager.shared.setupIfNeeded()
                    await LiveActivityController.startIfEnabled()
                    store.commit()
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// 前台也只给安静横幅，不响铃、不震动
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }
}
