import Foundation

struct DailyVerse: Equatable, Sendable {
    let reference: String
    let text: String
    let translation: String
    /// USFM identifier for the verse, e.g. "JHN.3.16".
    let usfm: String
    /// bible.com version id (59 = ESV, the default for the YouVersion daily verse).
    let versionID: Int
    let fetchedAt: Date

    /// Link to the full chapter on bible.com, e.g.
    /// https://www.bible.com/bible/59/JHN.3.ESV
    var chapterURL: URL {
        let parts = usfm.split(separator: ".")
        let book = parts.count > 0 ? String(parts[0]) : "JHN"
        let chapter = parts.count > 1 ? String(parts[1]) : "3"
        let abbreviation = translation.isEmpty ? "ESV" : translation
        let string = "https://www.bible.com/bible/\(versionID)/\(book).\(chapter).\(abbreviation)"
        return URL(string: string) ?? URL(string: "https://www.bible.com/verse-of-the-day")!
    }

    static let placeholder = DailyVerse(
        reference: "John 3:16",
        text: "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.",
        translation: "ESV",
        usfm: "JHN.3.16",
        versionID: 59,
        fetchedAt: .now
    )
}

enum VerseFetchError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "YouVersion API key is not configured."
        case .invalidResponse:
            return "Could not parse the daily verse."
        case .network(let error):
            return error.localizedDescription
        }
    }
}
