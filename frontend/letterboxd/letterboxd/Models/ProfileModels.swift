import Foundation

// Ovaj fajl sadrži modele za sve što ProfileView prikazuje osim onoga
// što je već pokriveno u User.swift (User, FavoriteMovie). Isti obrazac
// flexibleInt/flexibleDouble kao u Movie.swift — pg driver vraća
// BIGINT/NUMERIC kolone kao stringove (COUNT(*), rating, itd.), pa ne
// možemo se osloniti na običan Decodable sintetisan iz JSONDecoder-a.

struct UserEnvelope: Decodable {
    let user: User
}

// MARK: - Diary

// Odgovara redu iz diaryModel.findAllForUser (JOIN movies + LEFT JOIN
// ratings). `rating` je opcion jer diary_entries namerno nema svoju
// rating kolonu (videti handoff) — ovde samo čitamo rating ako postoji
// za isti (user, movie) par.
struct DiaryEntry: Decodable, Identifiable {
    let id: Int
    let movieId: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?
    let watchedDate: String?
    let createdAt: String?
    let isRewatch: Bool
    let note: String?
    let rating: Double?
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, movieId, title, releaseYear, posterUrl, watchedDate, createdAt, isRewatch, note, rating, tags
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        movieId = c.flexibleInt(.movieId) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        releaseYear = c.flexibleInt(.releaseYear)
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        watchedDate = try? c.decodeIfPresent(String.self, forKey: .watchedDate)
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        isRewatch = (try? c.decodeIfPresent(Bool.self, forKey: .isRewatch)) ?? false
        note = try? c.decodeIfPresent(String.self, forKey: .note)
        rating = c.flexibleDouble(.rating)
        tags = (try? c.decodeIfPresent([String].self, forKey: .tags)) ?? []
    }

    var asMovie: Movie {
        Movie(id: movieId, title: title, releaseYear: releaseYear, posterUrl: posterUrl)
    }
}

struct DiaryResponse: Decodable {
    let entries: [DiaryEntry]
}

// MARK: - Watchlist

// Odgovara redu iz watchlistModel.findAllForUser.
struct WatchlistItem: Decodable, Identifiable {
    let id: Int
    let movieId: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?

    enum CodingKeys: String, CodingKey { case id, movieId, title, releaseYear, posterUrl }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        movieId = c.flexibleInt(.movieId) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        releaseYear = c.flexibleInt(.releaseYear)
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
    }

    var asMovie: Movie {
        Movie(id: movieId, title: title, releaseYear: releaseYear, posterUrl: posterUrl)
    }
}

struct WatchlistResponse: Decodable {
    let watchlist: [WatchlistItem]
}

// MARK: - Lists

// Odgovara redu iz movie_lists (listModel.findAllForUser, SELECT *).
struct MovieListSummary: Decodable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey { case id, name, description, isPublic, createdAt }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        name = (try? c.decode(String.self, forKey: .name)) ?? "Untitled list"
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        isPublic = (try? c.decodeIfPresent(Bool.self, forKey: .isPublic)) ?? true
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

struct ListsResponse: Decodable {
    let lists: [MovieListSummary]
}

// MARK: - Likes (samo brojimo, ne treba nam sadržaj svakog lajka)

struct EmptyJSONObject: Decodable {}

struct LikesResponse: Decodable {
    let likes: [EmptyJSONObject]
}

// MARK: - Reviews (samo za tags, za "Tags" red u statistici)

struct UserReviewTags: Decodable {
    let tags: [String]
}

struct ReviewsTagsResponse: Decodable {
    let reviews: [UserReviewTags]
}

// MARK: - Stats (GET /api/stats/:userId)

struct StatsEnvelope: Decodable {
    let stats: StatsData
}

struct StatsData: Decodable {
    let summary: StatsSummary
    let topGenres: [StatsNamedCount]?
    let topDirectors: [StatsNamedCount]?
    let monthlyBreakdown: [StatsMonthCount]?
    let ratingsDistribution: [RatingBucket]
}

struct StatsNamedCount: Decodable, Identifiable {
    let name: String
    let count: Int
    var id: String { name }

    enum CodingKeys: String, CodingKey { case name, director, count }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? (try? c.decodeIfPresent(String.self, forKey: .director)) ?? "Unknown"
        count = c.flexibleInt(.count) ?? 0
    }
}

struct StatsMonthCount: Decodable, Identifiable {
    let month: Int
    let count: Int
    var id: Int { month }

    enum CodingKeys: String, CodingKey { case month, count }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        month = c.flexibleInt(.month) ?? 0
        count = c.flexibleInt(.count) ?? 0
    }
}

struct StatsSummary: Decodable {
    let moviesWatched: Int
    let totalRuntimeMinutes: Int
    let averageRating: Double?

    enum CodingKeys: String, CodingKey { case moviesWatched, totalRuntimeMinutes, averageRating }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        moviesWatched = c.flexibleInt(.moviesWatched) ?? 0
        totalRuntimeMinutes = c.flexibleInt(.totalRuntimeMinutes) ?? 0
        averageRating = c.flexibleDouble(.averageRating)
    }
}

// Jedna "kolona" u histogramu ocena (0.5 - 5.0, korak 0.5).
struct RatingBucket: Decodable, Identifiable {
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

// MARK: - Deljeni flexible-decode helperi (isti princip kao Movie.swift,
// ali `private extension` je po fajlu, pa mora svoja kopija ovde).

private extension KeyedDecodingContainer {
    func flexibleInt(_ key: Key) -> Int? {
        if let v = try? decodeIfPresent(Int.self, forKey: key) { return v }
        if let s = try? decodeIfPresent(String.self, forKey: key) { return Int(s ?? "") }
        return nil
    }
    func flexibleDouble(_ key: Key) -> Double? {
        if let v = try? decodeIfPresent(Double.self, forKey: key) { return v }
        if let s = try? decodeIfPresent(String.self, forKey: key) { return Double(s ?? "") }
        return nil
    }
}
