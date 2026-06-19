import Foundation

enum VerseFetcher {
    private static let bibleComURL = URL(string: "https://www.bible.com/verse-of-the-day")!
    private static let youVersionBase = URL(string: "https://api.youversion.com/v1")!

  #if WIDGET_EXTENSION
    private static let appKey: String? = Bundle.main.object(forInfoDictionaryKey: "YVPAppKey") as? String
  #else
    private static let appKey: String? = nil
  #endif

    static func fetchDailyVerse() async -> DailyVerse {
        if let key = appKey, !key.isEmpty, key != "YOUR_YVP_APP_KEY" {
            if let verse = try? await fetchFromYouVersionAPI(appKey: key) {
                return verse
            }
        }

        if let verse = try? await fetchFromBibleCom() {
            return verse
        }

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

    // MARK: - bible.com (YouVersion daily verse, no API key required)

    private static func fetchFromBibleCom() async throws -> DailyVerse {
        var request = URLRequest(url: bibleComURL)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8),
              let jsonData = extractNextDataJSON(from: html) else {
            throw VerseFetchError.invalidResponse
        }

        let page = try JSONDecoder().decode(BibleComNextData.self, from: jsonData)
        guard let verse = page.props.pageProps.verses.first else {
            throw VerseFetchError.invalidResponse
        }

        let reference = verse.reference.human
        let text = verse.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let translation = page.props.pageProps.versionData?.abbreviation ?? "ESV"
        let usfm = verse.reference.usfm.first ?? "JHN.3.16"

        return DailyVerse(
            reference: reference,
            text: text,
            translation: translation,
            usfm: usfm,
            versionID: 59,
            fetchedAt: .now
        )
    }

    private static func extractNextDataJSON(from html: String) -> Data? {
        let openTag = #"<script id="__NEXT_DATA__" type="application/json">"#
        guard let start = html.range(of: openTag) else { return nil }
        let jsonStart = start.upperBound
        guard let end = html.range(of: "</script>", range: jsonStart..<html.endIndex) else { return nil }
        return String(html[jsonStart..<end.lowerBound]).data(using: .utf8)
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

// MARK: - bible.com __NEXT_DATA__ models

private struct BibleComNextData: Decodable {
    let props: BibleComProps
}

private struct BibleComProps: Decodable {
    let pageProps: BibleComPageProps
}

private struct BibleComPageProps: Decodable {
    let verses: [BibleComVerse]
    let versionData: BibleComVersionData?
}

private struct BibleComVerse: Decodable {
    let reference: BibleComReference
    let content: String
}

private struct BibleComReference: Decodable {
    let human: String
    let usfm: [String]
}

private struct BibleComVersionData: Decodable {
    let abbreviation: String?
}
