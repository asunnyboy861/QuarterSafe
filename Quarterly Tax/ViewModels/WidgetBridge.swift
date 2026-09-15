import Foundation
import WidgetKit

enum WidgetKitBridge {
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
