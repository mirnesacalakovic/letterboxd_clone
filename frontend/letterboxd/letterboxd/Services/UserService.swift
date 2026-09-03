import Foundation


private struct UserSearchResponse: Decodable {
    let users: [ProfilePerson]
}

private struct FavoriteMoviesEnvelope: Decodable {
    let favoriteMovies: [FavoriteMovie]
}

// Svi pozivi vezani za profil ekran. Isti princip kao MovieService —
// jedna klasa po domenu, sve prolazi kroz APIClient.
final class UserService {
    static let shared = UserService()
    private init() {}

    // GET /api/users/:id — javno, radi i bez tokena (drugi korisnici
    // mogu da vide tuđ profil).
    func fetchProfile(id: Int) async throws -> User {
        let response: UserEnvelope = try await APIClient.shared.request(
            path: "/users/\(id)", method: .get, requiresAuth: false
        )
        return response.user
    }

    // Sopstveni dnevnik ide preko /diary (auth obavezan, vraća samo
    // trenutno ulogovanog), tuđi preko /users/:id/diary (javno).
    // limit=500 je "dovoljno veliko" da za normalnog korisnika u praksi
    // dobijemo ceo dnevnik — endpoint nema total count, pa je ovo
    // aproksimacija za "Diary" broj u statistici (videti ProfileViewModel).
    func fetchDiary(userId: Int, isOwnProfile: Bool, limit: Int = 500) async throws -> [DiaryEntry] {
        let path = isOwnProfile
            ? "/diary?limit=\(limit)&offset=0"
            : "/users/\(userId)/diary?limit=\(limit)&offset=0"
        let response: DiaryResponse = try await APIClient.shared.request(
            path: path, method: .get, requiresAuth: isOwnProfile
        )
        return response.entries
    }

    // GET /api/watchlist — backend nema javnu tuđu watchlistu, ovo je
    // uvek watchlist TRENUTNO ulogovanog korisnika.
    func fetchWatchlist(userId: Int? = nil, isOwnProfile: Bool = true) async throws -> [WatchlistItem] {
        let path = isOwnProfile ? "/watchlist" : "/users/\(userId ?? 0)/watchlist"
        let response: WatchlistResponse = try await APIClient.shared.request(
            path: path, method: .get, requiresAuth: isOwnProfile
        )
        return response.watchlist
    }

    // GET /api/lists — isto tako, samo sopstvene liste (privatne + javne).
    func fetchOwnLists() async throws -> [MovieListSummary] {
        let response: ListsResponse = try await APIClient.shared.request(
            path: "/lists", method: .get
        )
        return response.lists
    }

    // GET /api/users/:id/likes — brojimo samo dužinu niza.
    func fetchLikeCount(userId: Int) async throws -> Int {
        let response: LikesResponse = try await APIClient.shared.request(
            path: "/users/\(userId)/likes", method: .get, requiresAuth: false
        )
        return response.likes.count
    }

    // Letterboxd tags mogu da pripadaju log/diary unosu i bez review teksta.
    // Zato brojimo union tagova iz reviews + diary entries.
    func fetchDistinctTagCount(userId: Int) async throws -> Int {
        async let reviewsResponse: ReviewsTagsResponse = APIClient.shared.request(
            path: "/users/\(userId)/reviews", method: .get, requiresAuth: false
        )
        async let diaryResponse: DiaryResponse = APIClient.shared.request(
            path: "/users/\(userId)/diary?limit=500&offset=0", method: .get, requiresAuth: false
        )

        let (reviews, diary) = try await (reviewsResponse, diaryResponse)
        let allTags = reviews.reviews.flatMap(\.tags) + diary.entries.flatMap(\.tags)
        return Set(allTags).count
    }

    // GET /api/stats/:userId — bez ?year, znači "za sva vremena".
    func fetchStats(userId: Int) async throws -> StatsData {
        let response: StatsEnvelope = try await APIClient.shared.request(
            path: "/stats/\(userId)", method: .get, requiresAuth: false
        )
        return response.stats
    }
}

extension UserService {
    func fetchWatched(userId: Int, isOwnProfile: Bool) async throws -> [WatchedMovieItem] {
        let path = isOwnProfile ? "/watched" : "/users/\(userId)/films"
        let response: WatchedResponse = try await APIClient.shared.request(
            path: path, method: .get, requiresAuth: isOwnProfile
        )
        return response.watched
    }

    func fetchReviews(userId: Int) async throws -> [UserReviewItem] {
        let response: UserReviewsResponse = try await APIClient.shared.request(
            path: "/users/\(userId)/reviews", method: .get, requiresAuth: false
        )
        return response.reviews
    }

    func fetchLikes(userId: Int) async throws -> [LikedMovieItem] {
        let response: LikedMoviesResponse = try await APIClient.shared.request(
            path: "/users/\(userId)/likes", method: .get, requiresAuth: false
        )
        return response.likes
    }

    func fetchLists(userId: Int, isOwnProfile: Bool) async throws -> [MovieListSummary] {
        if isOwnProfile { return try await fetchOwnLists() }
        let response: ListsResponse = try await APIClient.shared.request(
            path: "/users/\(userId)/lists", method: .get, requiresAuth: false
        )
        return response.lists
    }

    func fetchFollowers(userId: Int) async throws -> [ProfilePerson] {
        let response: FollowersResponse = try await APIClient.shared.request(
            path: "/users/\(userId)/followers", method: .get, requiresAuth: false
        )
        return response.followers
    }

    func fetchFollowing(userId: Int) async throws -> [ProfilePerson] {
        let response: FollowingResponse = try await APIClient.shared.request(
            path: "/users/\(userId)/following", method: .get, requiresAuth: false
        )
        return response.following
    }

    func fetchListDetail(id: Int) async throws -> MovieListDetail {
        let response: MovieListDetailResponse = try await APIClient.shared.request(
            path: "/lists/\(id)", method: .get, requiresAuth: true
        )
        return response.list
    }

    func createList(name: String, description: String, isPublic: Bool) async throws -> MovieListSummary {
        struct Body: Encodable {
            let name: String
            let description: String
            let isPublic: Bool
        }

        let response: MovieListEnvelope = try await APIClient.shared.request(
            path: "/lists",
            method: .post,
            body: Body(name: name, description: description, isPublic: isPublic),
            requiresAuth: true
        )
        return response.list
    }

    func updateList(id: Int, name: String, description: String, isPublic: Bool) async throws -> MovieListSummary {
        struct Body: Encodable {
            let name: String
            let description: String
            let isPublic: Bool
        }

        let response: MovieListEnvelope = try await APIClient.shared.request(
            path: "/lists/\(id)",
            method: .put,
            body: Body(name: name, description: description, isPublic: isPublic),
            requiresAuth: true
        )
        return response.list
    }

    func addMovie(listId: Int, movieId: Int) async throws {
        struct IgnoreResponse: Decodable {}
        let _: IgnoreResponse = try await APIClient.shared.request(
            path: "/lists/\(listId)/movies/\(movieId)",
            method: .post,
            body: EmptyBody(),
            requiresAuth: true
        )
    }

    func removeMovie(listId: Int, movieId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/lists/\(listId)/movies/\(movieId)",
            method: .delete,
            requiresAuth: true
        )
    }

    func updateProfile(id: Int, username: String, bio: String) async throws -> User {
        struct Body: Encodable {
            let username: String
            let bio: String
        }
        let response: UserEnvelope = try await APIClient.shared.request(
            path: "/users/\(id)",
            method: .put,
            body: Body(username: username, bio: bio),
            requiresAuth: true
        )
        return response.user
    }

    func setFavorites(userId: Int, movieIds: [Int]) async throws -> [FavoriteMovie] {
        struct Body: Encodable {
            let movieIds: [Int]
        }

        let response: FavoriteMoviesEnvelope = try await APIClient.shared.request(
            path: "/users/\(userId)/favorites",
            method: .put,
            body: Body(movieIds: movieIds),
            requiresAuth: true
        )
        return response.favoriteMovies
    }





    func discoverLists(sortBy: String = "movieCount", limit: Int = 50) async throws -> [MovieListSummary] {
        let response: ListsResponse = try await APIClient.shared.request(
            path: "/lists/discover?sortBy=\(sortBy)&limit=\(limit)&offset=0",
            method: .get,
            requiresAuth: false
        )
        return response.lists
    }

    func searchUsers(_ query: String, limit: Int = 20) async throws -> [ProfilePerson] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        let response: UserSearchResponse = try await APIClient.shared.request(
            path: "/users/search?q=\(encoded)&limit=\(limit)&offset=0",
            method: .get,
            requiresAuth: false
        )
        return response.users
    }


    func isFollowing(currentUserId: Int, targetUserId: Int) async throws -> Bool {
        let following = try await fetchFollowing(userId: currentUserId)
        return following.contains { $0.id == targetUserId }
    }

    func follow(userId: Int) async throws {
        struct IgnoreResponse: Decodable {}
        let _: IgnoreResponse = try await APIClient.shared.request(
            path: "/users/\(userId)/follow",
            method: .post,
            body: EmptyBody(),
            requiresAuth: true
        )
    }

    func unfollow(userId: Int) async throws {
        struct IgnoreResponse: Decodable {}
        let _: IgnoreResponse = try await APIClient.shared.request(
            path: "/users/\(userId)/follow",
            method: .delete,
            requiresAuth: true
        )
    }

    func uploadAvatar(id: Int, jpegData: Data) async throws -> User {
        let response: UserEnvelope = try await APIClient.shared.uploadBinary(
            path: "/users/\(id)/avatar",
            data: jpegData,
            contentType: "image/jpeg",
            requiresAuth: true
        )
        return response.user
    }
}
