import SwiftUI
import WidgetKit

struct DailyVerseWidgetEntryView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    let entry: VerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.caption2)
                    .widgetAccentable()

                Text("Verse of the Day")
                    .font(.caption2.weight(.semibold))
                    .widgetAccentable()

                Spacer(minLength: 0)

                Text(entry.verse.translation)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            Text(entry.verse.reference)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .widgetAccentable()

            Text(entry.verse.text)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .lineLimit(renderingMode == .accented ? 5 : 6)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            background(for: entry.style)
        }
        .widgetURL(entry.verse.chapterURL)
    }

    @ViewBuilder
    private func background(for style: WidgetAppearanceStyle) -> some View {
        // In accented/clear desktop modes the system supplies its own glass,
        // so we stay transparent and let it take over.
        if renderingMode == .accented {
            Color.clear
        } else {
            switch style {
            case .liquid:
                liquidBackground
            case .frosted:
                Rectangle().fill(.ultraThinMaterial)
            case .clear:
                Color.clear
            }
        }
    }

    private var liquidBackground: some View {
        // A visibly glassy, tinted gradient layered over thin material.
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.30, green: 0.40, blue: 0.75).opacity(0.55),
                   Color(red: 0.45, green: 0.30, blue: 0.65).opacity(0.45)]
                : [Color(red: 0.55, green: 0.70, blue: 1.0).opacity(0.55),
                   Color(red: 0.75, green: 0.65, blue: 1.0).opacity(0.45)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .background(.ultraThinMaterial)
    }
}

#Preview(as: .systemSmall) {
    DailyVerseWidget()
} timeline: {
    VerseEntry(date: .now, verse: .placeholder, style: .liquid, isPlaceholder: false)
    VerseEntry(date: .now, verse: .placeholder, style: .frosted, isPlaceholder: false)
    VerseEntry(date: .now, verse: .placeholder, style: .clear, isPlaceholder: false)
}
