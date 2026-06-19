import WidgetKit
import SwiftUI

struct VerseEntry: TimelineEntry {
    let date: Date
    let verse: DailyVerse
    let style: WidgetAppearanceStyle
    let isPlaceholder: Bool
}

struct VerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, verse: .placeholder, style: .liquid, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

        Task {
            let verse = await VerseFetcher.fetchDailyVerse()
            completion(makeEntry(verse: verse))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        Task {
            let verse = await VerseFetcher.fetchDailyVerse()
            let entry = makeEntry(verse: verse)
            let refreshDate = nextMidnight(after: .now)
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }

    private func makeEntry(verse: DailyVerse) -> VerseEntry {
        VerseEntry(
            date: .now,
            verse: verse,
            style: WidgetSettings.appearance,
            isPlaceholder: false
        )
    }

    private func nextMidnight(after date: Date) -> Date {
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: date).addingTimeInterval(86_400)
        return startOfTomorrow.addingTimeInterval(5 * 60)
    }
}
