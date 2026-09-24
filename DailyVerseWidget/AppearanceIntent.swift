import AppIntents
import WidgetKit

/// Per-widget settings, shown when the user right-clicks the widget → Edit "Daily Verse".
/// Keeping this in the widget's own configuration (instead of an App Group shared with
/// the host app) means neither target needs a provisioning profile to launch.
struct AppearanceIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Appearance"
    static let description = IntentDescription("Choose how the Daily Verse widget looks on your desktop.")

    @Parameter(title: "Appearance", default: .liquid)
    var style: WidgetAppearanceStyle
}

extension WidgetAppearanceStyle: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Appearance"

    static let caseDisplayRepresentations: [WidgetAppearanceStyle: DisplayRepresentation] = [
        .liquid: DisplayRepresentation(title: "Liquid Glass", subtitle: "System glass, best on clear/tinted desktops"),
        .frosted: DisplayRepresentation(title: "Frosted", subtitle: "Light blur, easy to read on busy wallpapers"),
        .clear: DisplayRepresentation(title: "Fully Clear", subtitle: "Maximum transparency"),
    ]
}
