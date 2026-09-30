import Foundation
import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var backgroundStyle: BackgroundStyle = .gradient {
        didSet { saveSettings() }
    }
    
    @Published var solidColor: Color = Color(red: 0.07, green: 0.08, blue: 0.08) {
        didSet { saveSettings() }
    }
    
    @Published var gradientStart: Color = Color(red: 0.08, green: 0.09, blue: 0.09) {
        didSet { saveSettings() }
    }
    
    @Published var gradientEnd: Color = Color(red: 0.12, green: 0.18, blue: 0.15) {
        didSet { saveSettings() }
    }
    
    @Published var backgroundImageData: Data? {
        didSet { saveSettings() }
    }
    
    @Published var blurRadius: Double = 0 {
        didSet { saveSettings() }
    }
    
    @Published var showCompletedTodos: Bool = true {
        didSet { saveSettings() }
    }
    
    @Published var defaultFocusMinutes: Int = 25 {
        didSet { saveSettings() }
    }
    
    private let settingsKey = "app_settings"
    
    init() {
        loadSettings()
    }
    
    // 预设渐变方案
    let presetGradients: [(name: String, start: Color, end: Color)] = [
        ("深林", Color(red: 0.08, green: 0.09, blue: 0.09), Color(red: 0.12, green: 0.18, blue: 0.15)),
        ("炭黑", Color(red: 0.06, green: 0.06, blue: 0.07), Color(red: 0.14, green: 0.14, blue: 0.15)),
        ("墨蓝", Color(red: 0.07, green: 0.10, blue: 0.13), Color(red: 0.11, green: 0.16, blue: 0.20)),
        ("苔绿", Color(red: 0.08, green: 0.12, blue: 0.10), Color(red: 0.18, green: 0.24, blue: 0.17)),
        ("石墨", Color(red: 0.10, green: 0.10, blue: 0.11), Color(red: 0.20, green: 0.18, blue: 0.16)),
        ("暖灰", Color(red: 0.16, green: 0.14, blue: 0.12), Color(red: 0.24, green: 0.20, blue: 0.16)),
    ]
    
    let presetColors: [(name: String, color: Color)] = [
        ("炭黑", Color(red: 0.07, green: 0.08, blue: 0.08)),
        ("石墨", Color(red: 0.12, green: 0.12, blue: 0.13)),
        ("松绿", Color(red: 0.10, green: 0.16, blue: 0.13)),
        ("深蓝", Color(red: 0.09, green: 0.12, blue: 0.16)),
        ("陶土", Color(red: 0.21, green: 0.14, blue: 0.10)),
        ("雾白", Color(red: 0.88, green: 0.87, blue: 0.84)),
    ]
    
    func applyGradient(_ index: Int) {
        guard index < presetGradients.count else { return }
        gradientStart = presetGradients[index].start
        gradientEnd = presetGradients[index].end
        backgroundStyle = .gradient
    }
    
    func applyColor(_ index: Int) {
        guard index < presetColors.count else { return }
        solidColor = presetColors[index].color
        backgroundStyle = .solid
    }
    
    // MARK: - Persistence
    private struct SettingsData: Codable {
        var backgroundStyle: String
        var solidColorR: Double
        var solidColorG: Double
        var solidColorB: Double
        var gradientStartR: Double
        var gradientStartG: Double
        var gradientStartB: Double
        var gradientEndR: Double
        var gradientEndG: Double
        var gradientEndB: Double
        var blurRadius: Double
        var showCompletedTodos: Bool
        var defaultFocusMinutes: Int
        var backgroundImageData: Data?
    }
    
    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settingsData()) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) else { return }
        
        backgroundStyle = BackgroundStyle(rawValue: decoded.backgroundStyle) ?? .gradient
        solidColor = Color(red: decoded.solidColorR, green: decoded.solidColorG, blue: decoded.solidColorB)
        gradientStart = Color(red: decoded.gradientStartR, green: decoded.gradientStartG, blue: decoded.gradientStartB)
        gradientEnd = Color(red: decoded.gradientEndR, green: decoded.gradientEndG, blue: decoded.gradientEndB)
        blurRadius = decoded.blurRadius
        showCompletedTodos = decoded.showCompletedTodos
        defaultFocusMinutes = decoded.defaultFocusMinutes
        backgroundImageData = decoded.backgroundImageData
    }
    
    private func settingsData() -> SettingsData {
        let solid = UIColor(solidColor).cgColor.components ?? [0.1, 0.1, 0.15, 1]
        let gs = UIColor(gradientStart).cgColor.components ?? [1, 0.4, 0.3, 1]
        let ge = UIColor(gradientEnd).cgColor.components ?? [0.2, 0, 0.4, 1]
        
        return SettingsData(
            backgroundStyle: backgroundStyle.rawValue,
            solidColorR: Double(solid[0]), solidColorG: Double(solid[1]), solidColorB: Double(solid[2]),
            gradientStartR: Double(gs[0]), gradientStartG: Double(gs[1]), gradientStartB: Double(gs[2]),
            gradientEndR: Double(ge[0]), gradientEndG: Double(ge[1]), gradientEndB: Double(ge[2]),
            blurRadius: blurRadius,
            showCompletedTodos: showCompletedTodos,
            defaultFocusMinutes: defaultFocusMinutes,
            backgroundImageData: backgroundImageData
        )
    }
}
