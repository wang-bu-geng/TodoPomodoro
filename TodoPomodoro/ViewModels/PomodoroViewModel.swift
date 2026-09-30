import Foundation
import SwiftUI
import Combine
import UserNotifications
import ActivityKit

class PomodoroViewModel: ObservableObject {
    @Published var phase: PomodoroPhase = .focus
    @Published var secondsRemaining: Int
    @Published var isRunning = false
    @Published var completedSessions = 0
    @Published var totalFocusMinutes = 0
    @Published var focusMinutes: Int = 25 {
        didSet {
            saveTimerSettings()
            syncCurrentPhaseDurationIfIdle(.focus)
        }
    }
    @Published var shortBreakMinutes: Int = 5 {
        didSet {
            saveTimerSettings()
            syncCurrentPhaseDurationIfIdle(.shortBreak)
        }
    }
    @Published var longBreakMinutes: Int = 15 {
        didSet {
            saveTimerSettings()
            syncCurrentPhaseDurationIfIdle(.longBreak)
        }
    }
    @Published var sessionsBeforeLongBreak: Int = 4 {
        didSet { saveTimerSettings() }
    }
    @Published var showCompletionAnimation = false
    @Published var focusRequestedFromDetail = false
    @Published var focusTaskTitle: String = ""
    
    private var timer: Timer?
    private let sessionKey = "pomodoro_sessions"
    private let minutesKey = "pomodoro_minutes"
    private let focusMinutesKey = "pomodoro_focus_minutes"
    private let shortBreakMinutesKey = "pomodoro_short_break_minutes"
    private let longBreakMinutesKey = "pomodoro_long_break_minutes"
    private let sessionsBeforeLongBreakKey = "pomodoro_sessions_before_long_break"
    
    /// 当前的 Live Activity
    private var liveActivity: Activity<PomodoroActivityAttributes>?
    
    var progress: Double {
        let total = Double(currentPhaseTotalSeconds)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(secondsRemaining) / total)
    }
    
    var timeString: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var statusText: String {
        switch phase {
        case .focus:
            return "专注中"
        case .shortBreak:
            return "短休息"
        case .longBreak:
            return "长休息"
        }
    }
    
    init() {
        self.secondsRemaining = PomodoroPhase.focus.defaultMinutes * 60
        loadStats()
        loadTimerSettings()
        self.secondsRemaining = focusMinutes * 60
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        startLiveActivity()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        updateLiveActivity()
    }
    
    func reset() {
        pause()
        secondsRemaining = currentPhaseTotalSeconds
        endLiveActivity()
    }
    
    func skip() {
        completePhase()
    }
    
    private func tick() {
        guard secondsRemaining > 0 else {
            completePhase()
            return
        }
        secondsRemaining -= 1
        
        // 每 5 秒更新一次灵动岛（避免过于频繁）
        if secondsRemaining % 5 == 0 {
            updateLiveActivity()
        }
    }
    
    private func completePhase() {
        pause()
        endLiveActivity()
        
        if phase == .focus {
            completedSessions += 1
            totalFocusMinutes += focusMinutes
            saveStats()
            
            showCompletionAnimation = true
            
            // 发送本地通知
            sendNotification(title: "专注完成", body: "休息一下吧")
            
            // 先展示完成动画和绽放动效，再切换阶段
            let nextPhase: PomodoroPhase = completedSessions % sessionsBeforeLongBreak == 0 ? .longBreak : .shortBreak
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                showCompletionAnimation = false
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.switchTo(nextPhase)
                }
            }
        } else {
            // 休息结束，回到专注
            sendNotification(title: "休息结束", body: "开始新一轮专注吧")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.switchTo(.focus)
                }
                // 震动反馈
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
    
    func switchTo(_ newPhase: PomodoroPhase) {
        phase = newPhase
        secondsRemaining = totalSeconds(for: newPhase)
    }
    
    /// 滑动切换到下一阶段：专注 → 短休息 → 长休息 → 专注
    func switchToNextPhase() {
        switch phase {
        case .focus:        switchTo(.shortBreak)
        case .shortBreak:   switchTo(.longBreak)
        case .longBreak:    switchTo(.focus)
        }
    }
    
    /// 滑动切换到上一阶段：专注 → 长休息 → 短休息 → 专注
    func switchToPreviousPhase() {
        switch phase {
        case .focus:        switchTo(.longBreak)
        case .shortBreak:   switchTo(.focus)
        case .longBreak:    switchTo(.shortBreak)
        }
    }
    
    /// 从待办详情页启动专注：重置 → 设置任务名 → 开始 → 通知 ContentView 切 Tab
    func startFocusFromDetail(taskTitle: String) {
        reset()
        focusTaskTitle = taskTitle
        focusRequestedFromDetail = true
        start()
    }
    
    // MARK: - Live Activity
    
    @available(iOS 16.1, *)
    private func phaseNameForActivity() -> String {
        switch phase {
        case .focus: return "专注"
        case .shortBreak: return "短休"
        case .longBreak: return "长休"
        }
    }
    
    private func startLiveActivity() {
        guard #available(iOS 16.1, *) else { return }
        
        // 如果已有活跃 Activity，先结束
        if let existing = liveActivity {
            Task {
                await existing.end(ActivityContent(state: existing.content.state, staleDate: nil), dismissalPolicy: .immediate)
            }
        }
        
        let attributes = PomodoroActivityAttributes(startTime: Date())
        let initialState = PomodoroActivityAttributes.ContentState(
            remainingSeconds: secondsRemaining,
            totalSeconds: currentPhaseTotalSeconds,
            phaseName: phaseNameForActivity(),
            isRunning: true
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            liveActivity = activity
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func updateLiveActivity() {
        guard #available(iOS 16.1, *), let activity = liveActivity else { return }
        
        let contentState = PomodoroActivityAttributes.ContentState(
            remainingSeconds: secondsRemaining,
            totalSeconds: currentPhaseTotalSeconds,
            phaseName: phaseNameForActivity(),
            isRunning: isRunning
        )
        
        Task {
            await activity.update(
                .init(state: contentState, staleDate: Date().addingTimeInterval(30))
            )
        }
    }
    
    private func endLiveActivity() {
        guard #available(iOS 16.1, *), let activity = liveActivity else { return }
        
        // 结束前最后一次更新，把进度设为完成状态
        let finalState = PomodoroActivityAttributes.ContentState(
            remainingSeconds: 0,
            totalSeconds: currentPhaseTotalSeconds,
            phaseName: phaseNameForActivity(),
            isRunning: false
        )
        
        Task {
            // 用 end(_:dismissalPolicy:) 一次性结束并设置最终状态，无需 update + sleep
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        
        liveActivity = nil
    }
    
    // MARK: - Notifications
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func saveStats() {
        UserDefaults.standard.set(completedSessions, forKey: sessionKey)
        UserDefaults.standard.set(totalFocusMinutes, forKey: minutesKey)
    }
    
    private func loadStats() {
        completedSessions = UserDefaults.standard.integer(forKey: sessionKey)
        totalFocusMinutes = UserDefaults.standard.integer(forKey: minutesKey)
    }
    
    private func saveTimerSettings() {
        UserDefaults.standard.set(focusMinutes, forKey: focusMinutesKey)
        UserDefaults.standard.set(shortBreakMinutes, forKey: shortBreakMinutesKey)
        UserDefaults.standard.set(longBreakMinutes, forKey: longBreakMinutesKey)
        UserDefaults.standard.set(sessionsBeforeLongBreak, forKey: sessionsBeforeLongBreakKey)
    }
    
    private func loadTimerSettings() {
        let defaults = UserDefaults.standard
        let savedFocus = defaults.integer(forKey: focusMinutesKey)
        let savedShortBreak = defaults.integer(forKey: shortBreakMinutesKey)
        let savedLongBreak = defaults.integer(forKey: longBreakMinutesKey)
        let savedInterval = defaults.integer(forKey: sessionsBeforeLongBreakKey)
        
        focusMinutes = savedFocus > 0 ? savedFocus : focusMinutes
        shortBreakMinutes = savedShortBreak > 0 ? savedShortBreak : shortBreakMinutes
        longBreakMinutes = savedLongBreak > 0 ? savedLongBreak : longBreakMinutes
        sessionsBeforeLongBreak = savedInterval > 0 ? savedInterval : sessionsBeforeLongBreak
    }
    
    private var currentPhaseTotalSeconds: Int {
        totalSeconds(for: phase)
    }
    
    private func totalSeconds(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .focus:
            return focusMinutes * 60
        case .shortBreak:
            return shortBreakMinutes * 60
        case .longBreak:
            return longBreakMinutes * 60
        }
    }
    
    private func syncCurrentPhaseDurationIfIdle(_ changedPhase: PomodoroPhase) {
        guard !isRunning, phase == changedPhase else { return }
        secondsRemaining = totalSeconds(for: changedPhase)
    }
}
