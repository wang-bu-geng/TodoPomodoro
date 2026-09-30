import Foundation
import SwiftUI

struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    var hasDueDate: Bool
    var isCompleted: Bool
    var createdAt: Date
    var imageData: Data?
    var imageFilename: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        hasDueDate: Bool = false,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        imageData: Data? = nil,
        imageFilename: String? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasDueDate = hasDueDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.imageData = imageData
        self.imageFilename = imageFilename
    }
    
    var dueDateString: String {
        guard let date = dueDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, hasDueDate else { return false }
        return dueDate < Date() && !isCompleted
    }
    
    /// 截止日期颜色分级：7天以上绿，1-7天黄，24小时内橙，1小时内红，已过期红
    var dueDateColor: Color {
        guard let dueDate = dueDate, hasDueDate, !isCompleted else { return .white.opacity(0.5) }
        if isOverdue { return .red }
        let diff = Calendar.current.dateComponents([.day, .hour], from: Date(), to: dueDate)
        if let days = diff.day, days > 7 { return .green }
        if let days = diff.day, days >= 1 { return .yellow }
        // 不足24小时
        if let hours = diff.hour, hours >= 1 { return .orange }
        return .red
    }
    
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum PomodoroPhase: String, Codable, CaseIterable {
    case focus = "专注"
    case shortBreak = "短休息"
    case longBreak = "长休息"
    
    var color: Color {
        switch self {
        case .focus: return .orange
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }
    
    var defaultMinutes: Int {
        switch self {
        case .focus: return 25
        case .shortBreak: return 5
        case .longBreak: return 15
        }
    }
}

enum BackgroundStyle: String, Codable, CaseIterable {
    case solid = "纯色"
    case gradient = "渐变"
    case image = "图片"
    
    var systemImage: String {
        switch self {
        case .solid: return "circle.fill"
        case .gradient: return "circle.lefthalf.filled"
        case .image: return "photo.fill"
        }
    }
}
