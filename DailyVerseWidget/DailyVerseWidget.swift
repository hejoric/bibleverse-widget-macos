import WidgetKit
import SwiftUI

struct DailyVerseWidget: Widget {
    let kind = "DailyVerseWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: AppearanceIntent.self, provider: VerseProvider()) { entry in
            DailyVerseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Verse")
        .description("YouVersion verse of the day, refreshed each morning.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

@main
struct DailyVerseWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyVerseWidget()
    }
}
