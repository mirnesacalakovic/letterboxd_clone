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
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(userId: Int, isOwnProfile: Bool) {
        self.userId = userId
        self.isOwnProfile = isOwnProfile
    }

    var recentActivity: [DiaryEntry] { Array(diaryEntries.prefix(4)) }

    // "Diary" broj u statistici — endpoint nema total count, pa koristimo
    // dužinu niza koji smo povukli (videti komentar u UserService).
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
}
