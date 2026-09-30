import ActivityKit
import SwiftUI

/// Live Activity 元数据 — 番茄钟状态
struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 剩余秒数
        var remainingSeconds: Int
        /// 总时长（秒）
        var totalSeconds: Int
        /// 当前阶段名称
        var phaseName: String
        /// 是否正在运行
        var isRunning: Bool
    }
    
    /// 番茄钟开始时间
    var startTime: Date
}
