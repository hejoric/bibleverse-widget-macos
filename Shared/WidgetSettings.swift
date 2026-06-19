import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSettings {
    static let appGroupID = "group.com.hejoric.BibleVerse"
    private static let styleKey = "widgetAppearanceStyle"

    static var appearance: WidgetAppearanceStyle {
        get {
            guard let defaults = UserDefaults(suiteName: appGroupID),
                  let raw = defaults.string(forKey: styleKey),
                  let style = WidgetAppearanceStyle(rawValue: raw) else {
                return .liquid
            }
            return style
        }
        set {
            UserDefaults(suiteName: appGroupID)?.set(newValue.rawValue, forKey: styleKey)
            reloadWidget()
        }
    }

    private static func reloadWidget() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "DailyVerseWidget")
        #endif
    }
}
