import Foundation
internal import Combine

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published var movie: Movie
    @Published var stats = MoviePageStats.zero
    @Published var ratingsDistribution: [MovieRatingBucket] = []
    @Published var watchedBy: [MovieWatchedByUser] = []
    @Published var reviews: [MovieReview] = []
    @Published var similarMovies: [SimilarMovie] = []

    @Published var isWatched = false
    @Published var isInWatchlist = false
    @Published var isLiked = false
    @Published var userRating: Double?
    @Published var userReview: MovieUserReview?

    @Published var selectedReviewTab: MovieReviewPreviewTab = .popular
    @Published var isLoading = false
    @Published var isLoadingReviews = false
    @Published var message: String?

    init(movie: Movie) {
        self.movie = movie
    }

    func load() async {
        isLoading = true
        message = nil

        do {
            let page = try await MovieService.shared.page(id: movie.id)
            apply(page)

            do {
                similarMovies = try await MovieService.shared.similar(movieId: movie.id)
            } catch {
                similarMovies = []
            }

            await loadReviews()
        } catch {
            message = error.localizedDescription
        }

        isLoading = false
    }

    func refreshAfterLog() async {
        do {
            let page = try await MovieService.shared.page(id: movie.id)
            apply(page)
            await loadReviews()
        } catch {
            message = error.localizedDescription
        }
    }

    func selectReviewTab(_ tab: MovieReviewPreviewTab) async {
        guard selectedReviewTab != tab else { return }
        selectedReviewTab = tab
        await loadReviews()
    }

    func loadReviews() async {
        isLoadingReviews = true
        defer { isLoadingReviews = false }

        do {
            reviews = try await MovieService.shared.reviews(
                movieId: movie.id,
                filter: selectedReviewTab.apiFilter,
                sortBy: selectedReviewTab.sortBy,
                limit: 3
            )
        } catch {
            reviews = []
        }
    }

    func toggleWatched() async {
        await performToggle(
            current: isWatched,
            on: { try await MovieService.shared.markWatched(movieId: self.movie.id) },
            off: { try await MovieService.shared.removeWatched(movieId: self.movie.id) },
            update: { self.isWatched = $0 }
        )
    }

    func toggleWatchlist() async {
        await performToggle(
            current: isInWatchlist,
            on: { try await MovieService.shared.addToWatchlist(movieId: self.movie.id) },
            off: { try await MovieService.shared.removeFromWatchlist(movieId: self.movie.id) },
            update: { self.isInWatchlist = $0 }
        )
    }

    func toggleLike() async {
        await performToggle(
            current: isLiked,
            on: { try await MovieService.shared.likeMovie(movieId: self.movie.id) },
            off: { try await MovieService.shared.unlikeMovie(movieId: self.movie.id) },
            update: { self.isLiked = $0 }
        )
    }

    private func performToggle(
        current: Bool,
        on: () async throws -> Void,
        off: () async throws -> Void,
        update: (Bool) -> Void
    ) async {
        do {
            if current {
                try await off()
            } else {
                try await on()
            }
            update(!current)
        } catch {
            message = error.localizedDescription
        }
    }

    private func apply(_ response: MoviePageResponse) {
        movie = response.movie
        stats = response.stats
        ratingsDistribution = response.ratingsDistribution
        watchedBy = response.watchedBy
        isWatched = response.userState.watched
        isInWatchlist = response.userState.inWatchlist
        isLiked = response.userState.liked
        userRating = response.userState.rating
        userReview = response.userState.review
    }
}

@MainActor
final class ReviewDetailViewModel: ObservableObject {
    let review: MovieReview

    @Published var comments: [ReviewComment] = []
    @Published var likedByMe: Bool
    @Published var likeCount: Int
    @Published var commentCount: Int
    @Published var isLoadingComments = false
    @Published var isSavingComment = false
    @Published var message: String?

    init(review: MovieReview) {
        self.review = review
        likedByMe = review.likedByMe
        likeCount = review.likeCount
        commentCount = review.commentCount
    }

    func loadComments() async {
        isLoadingComments = true
        defer { isLoadingComments = false }

        do {
            comments = try await MovieService.shared.reviewComments(reviewId: review.id)
            commentCount = comments.count
        } catch {
            message = error.localizedDescription
        }
    }

    func toggleLike() async {
        let previous = likedByMe
        likedByMe.toggle()
        likeCount = max(0, likeCount + (likedByMe ? 1 : -1))

        do {
            if previous {
                try await MovieService.shared.unlikeReview(reviewId: review.id)
            } else {
                try await MovieService.shared.likeReview(reviewId: review.id)
            }
        } catch {
            likedByMe = previous
            likeCount = max(0, likeCount + (previous ? 1 : -1))
            message = error.localizedDescription
        }
    }

    func postComment(_ text: String) async -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return false }

        isSavingComment = true
        defer { isSavingComment = false }

        do {
            try await MovieService.shared.addReviewComment(reviewId: review.id, content: clean)
            await loadComments()
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }
}

private extension MoviePageStats {
    static var zero: MoviePageStats {
        MoviePageStats(membersCount: 0, reviewCount: 0, listCount: 0)
    }

    init(membersCount: Int, reviewCount: Int, listCount: Int) {
        self.membersCount = membersCount
        self.reviewCount = reviewCount
        self.listCount = listCount
    }
}
