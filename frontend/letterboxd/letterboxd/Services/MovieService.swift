import Foundation

private struct MovieIdBody: Encodable { let movieId: Int }
private struct RatingBody: Encodable { let movieId: Int; let rating: Double }
private struct ReviewBody: Encodable { let movieId: Int; let content: String; let rating: Double? }
private struct ReviewCommentBody: Encodable { let content: String }

final class MovieService {
    static let shared = MovieService()
    private init() {}

    func popular(limit: Int = 20) async throws -> [Movie] {
        let response: MoviesResponse = try await APIClient.shared.request(
            path: "/movies?sortBy=popular&limit=\(limit)&offset=0",
            method: .get,
            requiresAuth: false
        )
        return response.movies
    }

    func search(_ query: String, limit: Int = 20) async throws -> [Movie] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        let safeLimit = min(max(limit, 1), 200)
        let response: MoviesResponse = try await APIClient.shared.request(
            path: "/movies/search?q=\(encoded)&limit=\(safeLimit)&offset=0",
            method: .get,
            requiresAuth: false
        )
        return response.movies
    }



    func browse(sortBy: String, limit: Int = 100, offset: Int = 0) async throws -> [Movie] {
        let response: MoviesResponse = try await APIClient.shared.request(
            path: "/movies?sortBy=\(sortBy)&limit=\(limit)&offset=\(offset)",
            method: .get,
            requiresAuth: false
        )
        return response.movies
    }

    func browse(decade: Int, sortBy: String = "popular", limit: Int = 100) async throws -> [Movie] {
        let response: MoviesResponse = try await APIClient.shared.request(
            path: "/movies?decade=\(decade)&sortBy=\(sortBy)&limit=\(limit)&offset=0",
            method: .get,
            requiresAuth: false
        )
        return response.movies
    }

    func details(id: Int) async throws -> Movie {
        let response: MovieEnvelope = try await APIClient.shared.request(
            path: "/movies/\(id)",
            method: .get,
            requiresAuth: false
        )
        return response.movie
    }

    func page(id: Int) async throws -> MoviePageResponse {
        try await APIClient.shared.request(
            path: "/movies/\(id)/page",
            method: .get,
            requiresAuth: true
        )
    }

    func reviews(
        movieId: Int,
        filter: MovieReviewsFilter,
        sortBy: String = "newest",
        limit: Int = 50
    ) async throws -> [MovieReview] {
        let response: MovieReviewsResponse = try await APIClient.shared.request(
            path: "/movies/\(movieId)/reviews?filter=\(filter.rawValue)&sortBy=\(sortBy)&limit=\(limit)",
            method: .get,
            requiresAuth: true
        )
        return response.reviews
    }

    func reviewComments(reviewId: Int) async throws -> [ReviewComment] {
        let response: ReviewCommentsResponse = try await APIClient.shared.request(
            path: "/reviews/\(reviewId)/comments",
            method: .get,
            requiresAuth: true
        )
        return response.comments
    }

    func addReviewComment(reviewId: Int, content: String) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/reviews/\(reviewId)/comments",
            method: .post,
            body: ReviewCommentBody(content: content)
        )
    }

    func likeReview(reviewId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/reviews/\(reviewId)/like",
            method: .post
        )
    }

    func unlikeReview(reviewId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/reviews/\(reviewId)/like",
            method: .delete
        )
    }

    func members(movieId: Int, limit: Int = 200, offset: Int = 0) async throws -> MovieMembersResponse {
        try await APIClient.shared.request(
            path: "/movies/\(movieId)/members?limit=\(limit)&offset=\(offset)",
            method: .get,
            requiresAuth: true
        )
    }

    func containingLists(movieId: Int, limit: Int = 100, offset: Int = 0) async throws -> MovieContainingListsResponse {
        try await APIClient.shared.request(
            path: "/movies/\(movieId)/lists?limit=\(limit)&offset=\(offset)",
            method: .get,
            requiresAuth: true
        )
    }

    func similar(movieId: Int) async throws -> [SimilarMovie] {
        let response: SimilarMoviesResponse = try await APIClient.shared.request(
            path: "/movies/\(movieId)/similar",
            method: .get,
            requiresAuth: false
        )
        return response.similar
    }

    func markWatched(movieId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/watched",
            method: .post,
            body: MovieIdBody(movieId: movieId)
        )
    }

    func removeWatched(movieId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/watched/\(movieId)",
            method: .delete
        )
    }

    func addToWatchlist(movieId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/watchlist",
            method: .post,
            body: MovieIdBody(movieId: movieId)
        )
    }

    func removeFromWatchlist(movieId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/watchlist/\(movieId)",
            method: .delete
        )
    }

    func likeMovie(movieId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/movies/\(movieId)/like",
            method: .post
        )
    }

    func unlikeMovie(movieId: Int) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/movies/\(movieId)/like",
            method: .delete
        )
    }

    func rate(movieId: Int, rating: Double) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/ratings",
            method: .post,
            body: RatingBody(movieId: movieId, rating: rating)
        )
    }

    func review(movieId: Int, content: String, rating: Double?) async throws {
        let _: APIActionResponse = try await APIClient.shared.request(
            path: "/reviews",
            method: .post,
            body: ReviewBody(movieId: movieId, content: content, rating: rating)
        )
    }
}
