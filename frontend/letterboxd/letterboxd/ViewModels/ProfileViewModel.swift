import Foundation
internal import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    let userId: Int
    let isOwnProfile: Bool

    @Published var profile: User?
    @Published var diaryEntries: [DiaryEntry] = []
    @Published var watchlist: [WatchlistItem] = []
    @Published var lists: [MovieListSummary] = []
    @Published var likeCount = 0
    @Published var tagCount = 0
    @Published var ratingsDistribution: [RatingBucket] = []
    @Published var averageRating: Double?
    @Published var isFollowing = false
    @Published var isFollowLoading = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentUserId: Int?

    init(userId: Int, isOwnProfile: Bool) {
        self.userId = userId
        self.isOwnProfile = isOwnProfile
    }

    var recentActivity: [DiaryEntry] { Array(diaryEntries.prefix(4)) }
    var diaryCount: Int { diaryEntries.count }

    func loadAll() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            profile = try await UserService.shared.fetchProfile(id: userId)
            diaryEntries = try await UserService.shared.fetchDiary(userId: userId, isOwnProfile: isOwnProfile)
            likeCount = try await UserService.shared.fetchLikeCount(userId: userId)
            tagCount = try await UserService.shared.fetchDistinctTagCount(userId: userId)

            let stats = try await UserService.shared.fetchStats(userId: userId)
            ratingsDistribution = stats.ratingsDistribution
            averageRating = stats.summary.averageRating

            if isOwnProfile {
                lists = try await UserService.shared.fetchOwnLists()
                watchlist = try await UserService.shared.fetchWatchlist(userId: userId, isOwnProfile: true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadFollowState(currentUserId: Int?) async {
        self.currentUserId = currentUserId
        guard !isOwnProfile, let currentUserId, currentUserId != userId else {
            isFollowing = false
            return
        }

        do {
            isFollowing = try await UserService.shared.isFollowing(
                currentUserId: currentUserId,
                targetUserId: userId
            )
        } catch {
            // The rest of the public profile should remain usable even if the
            // follow-state request fails temporarily.
            isFollowing = false
        }
    }

    func toggleFollow() async {
        guard !isOwnProfile, currentUserId != nil, !isFollowLoading else { return }

        isFollowLoading = true
        errorMessage = nil
        let wasFollowing = isFollowing

        // Optimistic UI keeps the button responsive; a failed request is
        // immediately rolled back.
        isFollowing.toggle()

        do {
            if wasFollowing {
                try await UserService.shared.unfollow(userId: userId)
            } else {
                try await UserService.shared.follow(userId: userId)
            }

            profile = try await UserService.shared.fetchProfile(id: userId)
            NotificationCenter.default.post(name: .followRelationshipDidChange, object: nil)
        } catch {
            isFollowing = wasFollowing
            errorMessage = error.localizedDescription
        }

        isFollowLoading = false
    }
}

extension Notification.Name {
    static let followRelationshipDidChange = Notification.Name("followRelationshipDidChange")
}
