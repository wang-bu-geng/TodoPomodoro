import SwiftUI
import WidgetKit

@main
struct PomodoroWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            PomodoroLiveActivity()
        }
    }
}
