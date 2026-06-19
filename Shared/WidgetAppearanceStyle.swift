import Foundation

enum WidgetAppearanceStyle: String, CaseIterable, Identifiable, Sendable {
    case liquid
    case frosted
    case clear

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .liquid: "Liquid Glass"
        case .frosted: "Frosted"
        case .clear: "Fully Clear"
        }
    }

    var subtitle: String {
        switch self {
        case .liquid: "System glass — best on clear/tinted desktops"
        case .frosted: "Light blur, easy to read on busy wallpapers"
        case .clear: "Maximum transparency"
        }
    }
}
