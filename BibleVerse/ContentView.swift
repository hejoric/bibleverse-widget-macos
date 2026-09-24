import SwiftUI

struct ContentView: View {
    @State private var verse = DailyVerse.placeholder
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.secondary)
                Text("Daily Verse Widget")
                    .font(.headline)
            }

            Group {
                if isLoading {
                    ProgressView("Loading today's verse…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verse.reference)
                            .font(.title3.weight(.semibold))
                        Text(verse.text)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text(verse.translation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Widget appearance")
                    .font(.subheadline.weight(.semibold))

                ForEach(WidgetAppearanceStyle.allCases) { style in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(style.displayName)
                            .font(.caption.weight(.medium))
                        Text(style.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Right-click the widget → Edit “Daily Verse” to choose a style.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Add the widget")
                    .font(.subheadline.weight(.semibold))
                Text("Right-click the desktop → Edit Widgets → search “Daily Verse” → choose the small size (same as Battery).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            verse = await VerseFetcher.fetchDailyVerse()
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
