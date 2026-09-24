import Foundation
import OSLog

enum VerseFetcher {
    private static let logger = Logger(subsystem: "com.hejoric.BibleVerse", category: "VerseFetcher")

    /// Keyless YouVersion backend used by bible.com. The bible.com pages themselves now sit
    /// behind a JavaScript bot challenge, so they can't be scraped from a widget.
    private static let youVersionPublicBase = URL(string: "https://nodejs.bible.com/api")!
    private static let versionID = 59 // ESV, the default for the YouVersion daily verse
    private static let youVersionBase = URL(string: "https://api.youversion.com/v1")!

  #if WIDGET_EXTENSION
    private static let appKey: String? = Bundle.main.object(forInfoDictionaryKey: "YVPAppKey") as? String
  #else
    private static let appKey: String? = nil
  #endif

    static func fetchDailyVerse() async -> DailyVerse {
        if let key = appKey, !key.isEmpty, key != "YOUR_YVP_APP_KEY" {
            do {
                let verse = try await fetchFromYouVersionAPI(appKey: key)
                logger.info("Fetched \(verse.reference, privacy: .public) from YouVersion Platform API")
                return verse
            } catch {
                logger.error("YouVersion Platform API failed: \(error, privacy: .public)")
            }
        }

        do {
            let verse = try await fetchFromYouVersionPublicAPI()
            logger.info("Fetched \(verse.reference, privacy: .public) from YouVersion public API")
            return verse
        } catch {
            logger.error("YouVersion public API failed: \(error, privacy: .public)")
        }

        logger.error("All verse sources failed, showing placeholder")
        return .placeholder
    }

    // MARK: - YouVersion Platform API (optional, preferred when configured)

    private static func fetchFromYouVersionAPI(appKey: String) async throws -> DailyVerse {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1

        var votdRequest = URLRequest(
            url: youVersionBase.appending(path: "verse_of_the_days/\(dayOfYear)")
        )
        votdRequest.setValue(appKey, forHTTPHeaderField: "X-YVP-App-Key")

        let (votdData, votdResponse) = try await URLSession.shared.data(for: votdRequest)
        guard let http = votdResponse as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw VerseFetchError.invalidResponse
        }

        let votd = try JSONDecoder().decode(YouVersionVOTD.self, from: votdData)
        let passageID = votd.passageID

        var passageRequest = URLRequest(
            url: youVersionBase.appending(path: "bibles/59/passages/\(passageID)")
        )
        passageRequest.setValue(appKey, forHTTPHeaderField: "X-YVP-App-Key")

        let (passageData, passageResponse) = try await URLSession.shared.data(for: passageRequest)
        guard let passageHTTP = passageResponse as? HTTPURLResponse,
              (200...299).contains(passageHTTP.statusCode) else {
            throw VerseFetchError.invalidResponse
        }

        let passage = try JSONDecoder().decode(YouVersionPassageResponse.self, from: passageData)
        let content = passage.data.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let reference = passage.data.reference.human ?? passageID.replacingOccurrences(of: ".", with: " ")

        return DailyVerse(
            reference: reference,
            text: content,
            translation: passage.data.version?.abbreviation ?? "ESV",
            usfm: passageID,
            versionID: 59,
            fetchedAt: .now
        )
    }

    // MARK: - YouVersion public API (same daily verse as bible.com, no API key required)

    private static func fetchFromYouVersionPublicAPI() async throws -> DailyVerse {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1

        var votdURL = youVersionPublicBase.appending(path: "moments/votd/3.1")
        votdURL.append(queryItems: [URLQueryItem(name: "version_id", value: String(versionID))])
        let calendar: PublicVOTDCalendar = try await fetchJSON(from: votdURL)
        guard let usfms = calendar.votd.first(where: { $0.day == dayOfYear })?.usfm, !usfms.isEmpty else {
            throw VerseFetchError.invalidResponse
        }

        var versesURL = youVersionPublicBase.appending(path: "bible/verses/3.1")
        versesURL.append(queryItems: [
            URLQueryItem(name: "id", value: String(versionID)),
            URLQueryItem(name: "format", value: "text"),
        ] + usfms.enumerated().map { index, usfm in
            URLQueryItem(name: "references[\(index)]", value: usfm)
        })
        let passage: PublicVersesResponse = try await fetchJSON(from: versesURL)
        guard let first = passage.verses.first, let last = passage.verses.last else {
            throw VerseFetchError.invalidResponse
        }

        let text = passage.verses
            .map(\.content)
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        return DailyVerse(
            reference: combinedReference(first: first.reference.human, last: last.reference.human),
            text: text,
            translation: passage.localAbbreviation ?? "ESV",
            usfm: usfms[0],
            versionID: versionID,
            fetchedAt: .now
        )
    }

    private static func fetchJSON<T: Decodable>(from url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw VerseFetchError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// "Isaiah 43:18" + "Isaiah 43:19" → "Isaiah 43:18-19".
    private static func combinedReference(first: String, last: String) -> String {
        guard first != last else { return first }
        if let colon = first.lastIndex(of: ":"), last.hasPrefix(first[...colon]) {
            return first + "-" + last.dropFirst(first[...colon].count)
        }
        return "\(first)-\(last)"
    }
}

// MARK: - YouVersion API models

private struct YouVersionVOTD: Decodable {
    let passageID: String

    enum CodingKeys: String, CodingKey {
        case passageID = "passage_id"
    }
}

private struct YouVersionPassageResponse: Decodable {
    let data: YouVersionPassage
}

private struct YouVersionPassage: Decodable {
    let content: String
    let reference: YouVersionReference
    let version: YouVersionVersion?
}

private struct YouVersionReference: Decodable {
    let human: String?
}

private struct YouVersionVersion: Decodable {
    let abbreviation: String?
}

// MARK: - YouVersion public API models

private struct PublicVOTDCalendar: Decodable {
    let votd: [PublicVOTDDay]
}

private struct PublicVOTDDay: Decodable {
    let day: Int
    let usfm: [String]
}

private struct PublicVersesResponse: Decodable {
    let verses: [PublicVerse]
    let localAbbreviation: String?

    enum CodingKeys: String, CodingKey {
        case verses
        case localAbbreviation = "local_abbreviation"
    }
}

private struct PublicVerse: Decodable {
    let reference: PublicVerseReference
    let content: String
}

private struct PublicVerseReference: Decodable {
    let human: String
}
