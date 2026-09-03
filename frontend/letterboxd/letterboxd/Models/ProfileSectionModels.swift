import Foundation

struct WatchedMovieItem: Decodable, Identifiable {
    let id: Int
    let movieId: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?
    let watchedAt: String?

    enum CodingKeys: String, CodingKey { case id, movieId, title, releaseYear, posterUrl, watchedAt }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        movieId = c.flexibleInt(.movieId) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        releaseYear = c.flexibleInt(.releaseYear)
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        watchedAt = try? c.decodeIfPresent(String.self, forKey: .watchedAt)
    }

    var asMovie: Movie { Movie(id: movieId, title: title, releaseYear: releaseYear, posterUrl: posterUrl) }
}

struct WatchedResponse: Decodable { let watched: [WatchedMovieItem] }

struct UserReviewItem: Decodable, Identifiable {
    let id: Int
    let movieId: Int
    let content: String
    let isSpoiler: Bool
    let tags: [String]
    let createdAt: String?
    let title: String
    let posterUrl: String?
    let releaseYear: Int?
    let likeCount: Int

    enum CodingKeys: String, CodingKey {
        case id, movieId, content, isSpoiler, tags, createdAt, title, posterUrl, releaseYear, likeCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        movieId = c.flexibleInt(.movieId) ?? 0
        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        isSpoiler = (try? c.decodeIfPresent(Bool.self, forKey: .isSpoiler)) ?? false
        tags = (try? c.decodeIfPresent([String].self, forKey: .tags)) ?? []
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        releaseYear = c.flexibleInt(.releaseYear)
        likeCount = c.flexibleInt(.likeCount) ?? 0
    }

    var asMovie: Movie { Movie(id: movieId, title: title, releaseYear: releaseYear, posterUrl: posterUrl) }
}

struct UserReviewsResponse: Decodable { let reviews: [UserReviewItem] }

struct LikedMovieItem: Decodable, Identifiable {
    let movieId: Int
    let title: String
    let posterUrl: String?
    let releaseYear: Int?
    let createdAt: String?
    var id: Int { movieId }

    enum CodingKeys: String, CodingKey { case movieId, title, posterUrl, releaseYear, createdAt }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        movieId = c.flexibleInt(.movieId) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        releaseYear = c.flexibleInt(.releaseYear)
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
    }

    var asMovie: Movie { Movie(id: movieId, title: title, releaseYear: releaseYear, posterUrl: posterUrl) }
}

struct LikedMoviesResponse: Decodable { let likes: [LikedMovieItem] }

struct ProfilePerson: Decodable, Identifiable {
    let id: Int
    let username: String
    let avatarUrl: String?
    let bio: String?
}

struct FollowersResponse: Decodable { let followers: [ProfilePerson] }
struct FollowingResponse: Decodable { let following: [ProfilePerson] }

struct MovieListDetail: Decodable {
    let id: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let movies: [MovieListMovie]
}

struct MovieListMovie: Decodable, Identifiable {
    let movieId: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?
    var id: Int { movieId }
    var asMovie: Movie { Movie(id: movieId, title: title, releaseYear: releaseYear, posterUrl: posterUrl) }
}

struct MovieListDetailResponse: Decodable { let list: MovieListDetail }

private extension KeyedDecodingContainer {
    func flexibleInt(_ key: Key) -> Int? {
        if let v = try? decodeIfPresent(Int.self, forKey: key) { return v }
        if let s = try? decodeIfPresent(String.self, forKey: key) { return Int(s ?? "") }
        return nil
    }
}
