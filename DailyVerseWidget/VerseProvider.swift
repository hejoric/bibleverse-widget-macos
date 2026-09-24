import WidgetKit
import SwiftUI

struct VerseEntry: TimelineEntry {
    let date: Date
    let verse: DailyVerse
    let style: WidgetAppearanceStyle
    let isPlaceholder: Bool
}

struct VerseProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, verse: .placeholder, style: .liquid, isPlaceholder: true)
    }

    func snapshot(for configuration: AppearanceIntent, in context: Context) async -> VerseEntry {
        if context.isPreview {
            return VerseEntry(date: .now, verse: .placeholder, style: configuration.style, isPlaceholder: true)
        }

        let verse = await VerseFetcher.fetchDailyVerse()
        return makeEntry(verse: verse, style: configuration.style)
    }

    func timeline(for configuration: AppearanceIntent, in context: Context) async -> Timeline<VerseEntry> {
        let verse = await VerseFetcher.fetchDailyVerse()
        let entry = makeEntry(verse: verse, style: configuration.style)
        let refreshDate = nextMidnight(after: .now)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func makeEntry(verse: DailyVerse, style: WidgetAppearanceStyle) -> VerseEntry {
        VerseEntry(
            date: .now,
            verse: verse,
            style: style,
            isPlaceholder: false
        )
    }

    private func nextMidnight(after date: Date) -> Date {
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: date).addingTimeInterval(86_400)
        return startOfTomorrow.addingTimeInterval(5 * 60)
    }
}
