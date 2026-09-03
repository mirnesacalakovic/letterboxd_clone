import Foundation

struct LogStateEnvelope: Decodable {
    let state: LogState
}

struct LogState: Decodable {
    let rating: Double?
    let liked: Bool
    let hasWatched: Bool

    enum CodingKeys: String, CodingKey {
        case rating, liked, hasWatched
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rating = container.flexibleDouble(.rating)
        liked = (try? container.decode(Bool.self, forKey: .liked)) ?? false
        hasWatched = (try? container.decode(Bool.self, forKey: .hasWatched)) ?? false
    }
}

struct LogFilmRequest: Encodable {
    let movieId: Int
    let watchedDate: String
    let rating: Double?
    let liked: Bool
    let review: String
    let tags: [String]
    let isRewatch: Bool
    let isSpoiler: Bool
    let commentsAllowed: Bool

    enum CodingKeys: String, CodingKey {
        case movieId
        case watchedDate
        case rating
        case liked
        case review
        case tags
        case isRewatch
        case isSpoiler
        case commentsAllowed
    }

    // Rating is deliberately encoded as JSON null when there is no rating.
    // The backend uses that to distinguish “clear my rating” from a missing field.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(movieId, forKey: .movieId)
        try container.encode(watchedDate, forKey: .watchedDate)
        if let rating {
            try container.encode(rating, forKey: .rating)
        } else {
            try container.encodeNil(forKey: .rating)
        }
        try container.encode(liked, forKey: .liked)
        try container.encode(review, forKey: .review)
        try container.encode(tags, forKey: .tags)
        try container.encode(isRewatch, forKey: .isRewatch)
        try container.encode(isSpoiler, forKey: .isSpoiler)
        try container.encode(commentsAllowed, forKey: .commentsAllowed)
    }
}

struct LogSaveResponse: Decodable {
    let message: String?
}

private extension KeyedDecodingContainer {
    func flexibleDouble(_ key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return Double(stringValue ?? "")
        }
        return nil
    }
}
