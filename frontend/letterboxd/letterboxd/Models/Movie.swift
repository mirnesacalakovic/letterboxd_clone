import Foundation

struct Genre: Codable, Identifiable {
    let id: Int?
    let name: String
    var stableId: String { "\(id ?? 0)-\(name)" }
    var idValue: String { stableId }
}

struct Movie: Decodable, Identifiable {
    let id: Int
    let title: String
    let releaseYear: Int?
    let director: String?
    let overview: String?
    let runtimeMinutes: Int?
    let cast: [String]
    let keywords: [String]
    let posterUrl: String?
    let backdropUrl: String?
    let averageRating: Double?
    let ratingCount: Int?
    let likeCount: Int?
    let genres: [String]

    enum CodingKeys: String, CodingKey {
        case id, title, releaseYear, director, overview, runtimeMinutes, runtime
        case cast, actors, keywords, posterUrl, backdropUrl, averageRating, ratingCount, likeCount, genres
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        releaseYear = c.flexibleInt(.releaseYear)
        director = try? c.decodeIfPresent(String.self, forKey: .director)
        overview = try? c.decodeIfPresent(String.self, forKey: .overview)
        runtimeMinutes = c.flexibleInt(.runtimeMinutes) ?? c.flexibleInt(.runtime)

        if let names = try? c.decodeIfPresent([String].self, forKey: .cast) {
            cast = names ?? []
        } else if let names = try? c.decodeIfPresent([String].self, forKey: .actors) {
            cast = names ?? []
        } else {
            cast = []
        }

        keywords = (try? c.decodeIfPresent([String].self, forKey: .keywords)) ?? []
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        backdropUrl = try? c.decodeIfPresent(String.self, forKey: .backdropUrl)
        averageRating = c.flexibleDouble(.averageRating)
        ratingCount = c.flexibleInt(.ratingCount)
        likeCount = c.flexibleInt(.likeCount)

        if let names = try? c.decodeIfPresent([String].self, forKey: .genres) {
            genres = names ?? []
        } else if let objects = try? c.decodeIfPresent([Genre].self, forKey: .genres) {
            genres = (objects ?? []).map(\.name)
        } else {
            genres = []
        }
    }

    init(
        id: Int,
        title: String,
        releaseYear: Int? = nil,
        director: String? = nil,
        overview: String? = nil,
        runtimeMinutes: Int? = nil,
        cast: [String] = [],
        keywords: [String] = [],
        posterUrl: String? = nil,
        backdropUrl: String? = nil,
        averageRating: Double? = nil,
        ratingCount: Int? = nil,
        likeCount: Int? = nil,
        genres: [String] = []
    ) {
        self.id = id
        self.title = title
        self.releaseYear = releaseYear
        self.director = director
        self.overview = overview
        self.runtimeMinutes = runtimeMinutes
        self.cast = cast
        self.keywords = keywords
        self.posterUrl = posterUrl
        self.backdropUrl = backdropUrl
        self.averageRating = averageRating
        self.ratingCount = ratingCount
        self.likeCount = likeCount
        self.genres = genres
    }
}

private extension KeyedDecodingContainer {
    func flexibleInt(_ key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
        if let string = try? decodeIfPresent(String.self, forKey: key) { return Int(string ?? "") }
        return nil
    }

    func flexibleDouble(_ key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
        if let string = try? decodeIfPresent(String.self, forKey: key) { return Double(string ?? "") }
        return nil
    }
}

struct MoviesResponse: Decodable {
    let movies: [Movie]
    let total: Int

    enum CodingKeys: String, CodingKey { case movies, data, total }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        movies = (try? c.decode([Movie].self, forKey: .movies))
            ?? (try? c.decode([Movie].self, forKey: .data))
            ?? []

        if let number = try? c.decode(Int.self, forKey: .total) {
            total = number
        } else if let string = try? c.decode(String.self, forKey: .total), let number = Int(string) {
            total = number
        } else {
            total = movies.count
        }
    }
}

struct MovieEnvelope: Decodable {
    let movie: Movie

    enum CodingKeys: String, CodingKey { case movie, data }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if c.contains(.movie) {
            movie = try c.decode(Movie.self, forKey: .movie)
            return
        }
        if c.contains(.data) {
            movie = try c.decode(Movie.self, forKey: .data)
            return
        }
        movie = try Movie(from: decoder)
    }
}

struct APIActionResponse: Decodable {
    let message: String?
}

// MARK: - Movie page

struct MoviePageStats: Decodable {
    let membersCount: Int
    let reviewCount: Int
    let listCount: Int

    enum CodingKeys: String, CodingKey { case membersCount, reviewCount, listCount }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        membersCount = c.flexibleInt(.membersCount) ?? 0
        reviewCount = c.flexibleInt(.reviewCount) ?? 0
        listCount = c.flexibleInt(.listCount) ?? 0
    }
}

struct MovieRatingBucket: Decodable, Identifiable {
    let rating: Double
    let count: Int
    var id: Double { rating }

    enum CodingKeys: String, CodingKey { case rating, count }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rating = c.flexibleDouble(.rating) ?? 0
        count = c.flexibleInt(.count) ?? 0
    }
}

struct MovieWatchedByUser: Decodable, Identifiable {
    let userId: Int
    let username: String
    let avatarUrl: String?
    let rating: Double?
    let isRewatch: Bool
    var id: Int { userId }

    enum CodingKeys: String, CodingKey { case userId, username, avatarUrl, rating, isRewatch }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = c.flexibleInt(.userId) ?? 0
        username = (try? c.decode(String.self, forKey: .username)) ?? "member"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        rating = c.flexibleDouble(.rating)
        isRewatch = (try? c.decode(Bool.self, forKey: .isRewatch)) ?? false
    }
}

struct MovieUserReview: Decodable, Identifiable {
    let id: Int
    let content: String
    let isSpoiler: Bool
    let createdAt: String?
    let rating: Double?

    enum CodingKeys: String, CodingKey { case id, content, isSpoiler, createdAt, rating }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        isSpoiler = (try? c.decode(Bool.self, forKey: .isSpoiler)) ?? false
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        rating = c.flexibleDouble(.rating)
    }
}

struct MovieUserState: Decodable {
    let watched: Bool
    let inWatchlist: Bool
    let liked: Bool
    let rating: Double?
    let review: MovieUserReview?
}

struct MoviePageResponse: Decodable {
    let movie: Movie
    let stats: MoviePageStats
    let ratingsDistribution: [MovieRatingBucket]
    let watchedBy: [MovieWatchedByUser]
    let userState: MovieUserState
}

// MARK: - Movie reviews

enum MovieReviewsFilter: String, CaseIterable {
    case everyone
    case friends
    case you
    case liked

    var title: String {
        switch self {
        case .everyone: return "Everyone"
        case .friends: return "Friends"
        case .you: return "You"
        case .liked: return "Liked"
        }
    }
}

enum MovieReviewPreviewTab: String, CaseIterable {
    case popular
    case friends
    case you
    case liked

    var title: String { rawValue.capitalized }

    var apiFilter: MovieReviewsFilter {
        switch self {
        case .popular: return .everyone
        case .friends: return .friends
        case .you: return .you
        case .liked: return .liked
        }
    }

    var sortBy: String {
        self == .popular ? "mostLiked" : "newest"
    }
}

struct MovieReview: Decodable, Identifiable {
    let id: Int
    let userId: Int
    let diaryEntryId: Int?
    let content: String
    let isSpoiler: Bool
    let tags: [String]
    let commentsEnabled: Bool
    let createdAt: String?
    let updatedAt: String?
    let username: String
    let avatarUrl: String?
    let rating: Double?
    let isRewatch: Bool
    let likedMovie: Bool
    let likeCount: Int
    let likedByMe: Bool
    let commentCount: Int

    enum CodingKeys: String, CodingKey {
        case id, userId, diaryEntryId, content, isSpoiler, tags, commentsEnabled
        case createdAt, updatedAt, username, avatarUrl, rating, isRewatch
        case likedMovie, likeCount, likedByMe, commentCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        userId = c.flexibleInt(.userId) ?? 0
        diaryEntryId = c.flexibleInt(.diaryEntryId)
        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        isSpoiler = (try? c.decode(Bool.self, forKey: .isSpoiler)) ?? false
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        commentsEnabled = (try? c.decode(Bool.self, forKey: .commentsEnabled)) ?? true
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try? c.decodeIfPresent(String.self, forKey: .updatedAt)
        username = (try? c.decode(String.self, forKey: .username)) ?? "member"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        rating = c.flexibleDouble(.rating)
        isRewatch = (try? c.decode(Bool.self, forKey: .isRewatch)) ?? false
        likedMovie = (try? c.decode(Bool.self, forKey: .likedMovie)) ?? false
        likeCount = c.flexibleInt(.likeCount) ?? 0
        likedByMe = (try? c.decode(Bool.self, forKey: .likedByMe)) ?? false
        commentCount = c.flexibleInt(.commentCount) ?? 0
    }
}

struct MovieReviewsResponse: Decodable {
    let reviews: [MovieReview]
}

struct ReviewComment: Decodable, Identifiable {
    let id: Int
    let reviewId: Int
    let content: String
    let createdAt: String?
    let updatedAt: String?
    let userId: Int
    let username: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, reviewId, content, createdAt, updatedAt, userId, username, avatarUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        reviewId = c.flexibleInt(.reviewId) ?? 0
        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try? c.decodeIfPresent(String.self, forKey: .updatedAt)
        userId = c.flexibleInt(.userId) ?? 0
        username = (try? c.decode(String.self, forKey: .username)) ?? "member"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
    }
}

struct ReviewCommentsResponse: Decodable {
    let comments: [ReviewComment]
}

// MARK: - Movie members

struct MovieMember: Decodable, Identifiable {
    let userId: Int
    let username: String
    let avatarUrl: String?
    let bio: String?
    let rating: Double?
    let watchedAt: String?
    let isFollowing: Bool
    let isCurrentUser: Bool

    var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId, username, avatarUrl, bio, rating, watchedAt, isFollowing, isCurrentUser
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = c.flexibleInt(.userId) ?? 0
        username = (try? c.decode(String.self, forKey: .username)) ?? "member"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        bio = try? c.decodeIfPresent(String.self, forKey: .bio)
        rating = c.flexibleDouble(.rating)
        watchedAt = try? c.decodeIfPresent(String.self, forKey: .watchedAt)
        isFollowing = (try? c.decode(Bool.self, forKey: .isFollowing)) ?? false
        isCurrentUser = (try? c.decode(Bool.self, forKey: .isCurrentUser)) ?? false
    }
}

struct MovieMembersResponse: Decodable {
    let members: [MovieMember]
    let total: Int

    enum CodingKeys: String, CodingKey { case members, total }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        members = (try? c.decode([MovieMember].self, forKey: .members)) ?? []
        total = c.flexibleInt(.total) ?? members.count
    }
}

// MARK: - Lists containing movie

struct MovieContainingList: Decodable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let createdAt: String?
    let userId: Int
    let username: String
    let avatarUrl: String?
    let movieCount: Int
    let posterUrls: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, description, isPublic, createdAt
        case userId, username, avatarUrl, movieCount, posterUrls
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        name = (try? c.decode(String.self, forKey: .name)) ?? "Untitled list"
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        isPublic = (try? c.decode(Bool.self, forKey: .isPublic)) ?? true
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        userId = c.flexibleInt(.userId) ?? 0
        username = (try? c.decode(String.self, forKey: .username)) ?? "member"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        movieCount = c.flexibleInt(.movieCount) ?? 0
        posterUrls = (try? c.decode([String].self, forKey: .posterUrls)) ?? []
    }
}

struct MovieContainingListsResponse: Decodable {
    let lists: [MovieContainingList]
    let total: Int

    enum CodingKeys: String, CodingKey { case lists, total }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lists = (try? c.decode([MovieContainingList].self, forKey: .lists)) ?? []
        total = c.flexibleInt(.total) ?? lists.count
    }
}

// MARK: - Similar films

struct SimilarMovie: Decodable, Identifiable {
    let movieId: Int
    let title: String
    let posterUrl: String?
    let score: Double
    var id: Int { movieId }

    enum CodingKeys: String, CodingKey { case movieId, title, posterUrl, score }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        movieId = c.flexibleInt(.movieId) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        score = c.flexibleDouble(.score) ?? 0
    }

    var asMovie: Movie {
        Movie(id: movieId, title: title, posterUrl: posterUrl)
    }
}

struct SimilarMoviesResponse: Decodable {
    let similar: [SimilarMovie]
}
