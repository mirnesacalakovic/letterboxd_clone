import Foundation

enum ActivityTab: String, CaseIterable, Hashable {
    case friends
    case you
    case incoming

    var title: String {
        switch self {
        case .friends: return "Friends"
        case .you: return "You"
        case .incoming: return "Incoming"
        }
    }
}


enum ActivityFilter: String, CaseIterable, Hashable, Identifiable {
    case reviews
    case ratings
    case watched
    case watchlist
    case likes
    case comments
    case follows

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reviews: return "Reviews"
        case .ratings: return "Ratings"
        case .watched: return "Watched films"
        case .watchlist: return "Watchlist"
        case .likes: return "Review likes"
        case .comments: return "Comments"
        case .follows: return "New followers"
        }
    }

    var icon: String {
        switch self {
        case .reviews: return "text.bubble"
        case .ratings: return "star"
        case .watched: return "eye"
        case .watchlist: return "bookmark"
        case .likes: return "heart"
        case .comments: return "bubble.left"
        case .follows: return "person.badge.plus"
        }
    }

    func matches(_ activity: ActivityItem) -> Bool {
        switch self {
        case .reviews: return activity.type == "review"
        case .ratings: return activity.type == "rating"
        case .watched: return activity.type == "watched"
        case .watchlist: return activity.type == "watchlist"
        case .likes: return activity.type == "review_like"
        case .comments: return activity.type == "comment"
        case .follows: return activity.type == "follow"
        }
    }
}

struct ActivityResponse: Decodable {
    let activities: [ActivityItem]
}

struct ActivityItem: Decodable, Identifiable {
    let type: String
    let sourceId: String
    let occurredAt: String

    let userId: Int
    let username: String
    let avatarUrl: String?

    let movieId: Int?
    let title: String?
    let releaseYear: Int?
    let posterUrl: String?

    let rating: Double?
    let extra: String?
    let isSpoiler: Bool?
    let reviewId: Int?

    var id: String { "\(type)-\(sourceId)" }

    enum CodingKeys: String, CodingKey {
        case type, sourceId, occurredAt
        case userId, username, avatarUrl
        case movieId, title, releaseYear, posterUrl
        case rating, extra, isSpoiler, reviewId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        type = (try? c.decode(String.self, forKey: .type)) ?? "activity"
        sourceId = c.flexibleString(.sourceId) ?? UUID().uuidString
        occurredAt = (try? c.decode(String.self, forKey: .occurredAt)) ?? ""

        userId = c.flexibleInt(.userId) ?? 0
        username = (try? c.decode(String.self, forKey: .username)) ?? "Unknown"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)

        movieId = c.flexibleInt(.movieId)
        title = try? c.decodeIfPresent(String.self, forKey: .title)
        releaseYear = c.flexibleInt(.releaseYear)
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)

        rating = c.flexibleDouble(.rating)
        extra = try? c.decodeIfPresent(String.self, forKey: .extra)
        isSpoiler = try? c.decodeIfPresent(Bool.self, forKey: .isSpoiler)
        reviewId = c.flexibleInt(.reviewId)
    }

    var movie: Movie? {
        guard let movieId, let title else { return nil }
        return Movie(
            id: movieId,
            title: title,
            releaseYear: releaseYear,
            posterUrl: posterUrl
        )
    }

    var relativeTime: String {
        guard let date = ActivityDateParser.date(from: occurredAt) else { return "" }
        return ActivityDateParser.relative.localizedString(for: date, relativeTo: Date())
    }
}

private enum ActivityDateParser {
    static let isoWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    static func date(from value: String) -> Date? {
        if let parsed = isoWithFractional.date(from: value) { return parsed }
        if let parsed = iso.date(from: value) { return parsed }

        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        if let parsed = fallback.date(from: value) { return parsed }
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return fallback.date(from: value)
    }
}

private extension KeyedDecodingContainer {
    func flexibleInt(_ key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
        if let text = try? decodeIfPresent(String.self, forKey: key) { return Int(text ?? "") }
        return nil
    }

    func flexibleDouble(_ key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
        if let text = try? decodeIfPresent(String.self, forKey: key) { return Double(text ?? "") }
        return nil
    }

    func flexibleString(_ key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return String(value ?? 0) }
        return nil
    }
}
