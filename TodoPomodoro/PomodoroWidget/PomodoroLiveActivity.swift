import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // ---- 锁屏 / 通知中心视图 ----
            LockScreenLiveActivityView(context: context)
            
        } dynamicIsland: { context in
            // ---- 灵动岛 ----
            DynamicIsland {
                // 展开态（长按或点击灵动岛）
                DynamicIslandExpandedRegion(.leading) {
                    phaseIcon(context.state.phaseName)
                        .foregroundStyle(phaseColor(context.state.phaseName))
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    phaseLabel(context.state.phaseName)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    timerContent(context: context)
                }
            } compactLeading: {
                // 紧凑态 — 左侧（显示番茄图标）
                phaseIcon(context.state.phaseName)
                    .font(.system(size: 12))
                    .foregroundStyle(phaseColor(context.state.phaseName))
            } compactTrailing: {
                // 紧凑态 — 右侧（显示倒计时）
                compactTimer(context.state)
            } minimal: {
                // 极简态（另一个灵动岛同时活跃时）
                phaseIcon(context.state.phaseName)
                    .font(.system(size: 12))
                    .foregroundStyle(phaseColor(context.state.phaseName))
            }
        }
    }
    
    // MARK: - 紧凑计时
    
    private func compactTimer(_ state: PomodoroActivityAttributes.ContentState) -> some View {
        let minutes = state.remainingSeconds / 60
        let seconds = state.remainingSeconds % 60
        
        return Text(String(format: "%02d:%02d", minutes, seconds))
            .font(.system(.caption2, design: .monospaced))
            .fontWeight(.bold)
            .foregroundStyle(phaseColor(state.phaseName))
            .monospacedDigit()
            .contentTransition(.numericText())
    }
    
    // MARK: - 展开底部
    
    private func timerContent(context: ActivityViewContext<PomodoroActivityAttributes>) -> some View {
        let state = context.state
        let progress = Double(state.totalSeconds - state.remainingSeconds) / Double(state.totalSeconds)
        let minutes = state.remainingSeconds / 60
        let seconds = state.remainingSeconds % 60
        
        return HStack(spacing: 16) {
            // 进度圆环
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: 4)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        phaseColor(state.phaseName),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                
                Text(String(format: "%02d:%02d", minutes, seconds))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    phaseIcon(state.phaseName)
                        .font(.caption)
                    Text(state.phaseName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(phaseColor(state.phaseName))
                
                Text("始于 \(context.attributes.startTime, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                
                if !state.isRunning {
                    Label("已暂停", systemImage: "pause.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - 辅助
    
    private func phaseIcon(_ name: String) -> some View {
        switch name {
        case "专注": return Image(systemName: "timer")
        case "短休": return Image(systemName: "cup.and.saucer.fill")
        case "长休": return Image(systemName: "bed.double.fill")
        default: return Image(systemName: "timer")
        }
    }
    
    private func phaseLabel(_ name: String) -> some View {
        Text(name)
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(phaseColor(name))
    }
    
    private func phaseColor(_ name: String) -> Color {
        switch name {
        case "专注": return .orange
        case "短休": return .green
        case "长休": return .blue
        default: return .orange
        }
    }
}

// MARK: - 锁屏视图

@available(iOS 16.1, *)
private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>
    
    var body: some View {
        let state = context.state
        let progress = Double(state.totalSeconds - state.remainingSeconds) / Double(state.totalSeconds)
        let minutes = state.remainingSeconds / 60
        let seconds = state.remainingSeconds % 60
        
        HStack(spacing: 20) {
            // 左侧圆环
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: 6)
                    .frame(width: 64, height: 64)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        phaseColor(state.phaseName),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text(String(format: "%02d", minutes))
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                    Text(String(format: "%02d", seconds))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .monospacedDigit()
                .contentTransition(.numericText())
            }
            
            // 右侧信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    phaseIcon(state.phaseName)
                        .font(.subheadline)
                    Text(state.phaseName)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundStyle(phaseColor(state.phaseName))
                
                Text("\(state.totalSeconds / 60) 分钟 · 始于 \(context.attributes.startTime, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                
                if !state.isRunning {
                    Label("已暂停", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
        }
        .padding()
        .activitySystemActionForegroundColor(.white)
        .activityBackgroundTint(.black.opacity(0.7))
    }
    
    private func phaseIcon(_ name: String) -> some View {
        switch name {
        case "专注": return Image(systemName: "timer")
        case "短休": return Image(systemName: "cup.and.saucer.fill")
        case "长休": return Image(systemName: "bed.double.fill")
        default: return Image(systemName: "timer")
        }
    }
    
    private func phaseColor(_ name: String) -> Color {
        switch name {
        case "专注": return .orange
        case "短休": return .green
        case "长休": return .blue
        default: return .orange
        }
    }
}
