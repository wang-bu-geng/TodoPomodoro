import SwiftUI
import UserNotifications

@main
struct TodoPomodoroApp: App {
    @StateObject private var todoVM = TodoViewModel()
    @StateObject private var pomodoroVM = PomodoroViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    
    init() {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        // 自定义 tab bar 外观
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // 让 TabView 内容区透明，确保底部 BackgroundView 透出
        UIView.appearance(whenContainedInInstancesOf: [UITabBarController.self]).backgroundColor = .clear
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        
        // 自定义 navigation bar 外观
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(todoVM)
                .environmentObject(pomodoroVM)
                .environmentObject(settingsVM)
        }
    }
}
