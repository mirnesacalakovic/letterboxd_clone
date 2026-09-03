import Foundation
internal import Combine

@MainActor
final class ActivityViewModel: ObservableObject {
    @Published var selectedTab: ActivityTab = .friends
    @Published private(set) var activities: [ActivityItem] = []
    @Published var activeFilters: Set<ActivityFilter> = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: ActivityService
    private var loadGeneration = 0

    init(service: ActivityService = .shared) {
        self.service = service
    }

    var availableFilters: [ActivityFilter] {
        switch selectedTab {
        case .friends, .you:
            return [.reviews, .ratings, .watched, .watchlist]
        case .incoming:
            return [.likes, .comments, .follows]
        }
    }

    var filteredActivities: [ActivityItem] {
        guard !activeFilters.isEmpty else { return activities }
        return activities.filter { activity in
            activeFilters.contains { $0.matches(activity) }
        }
    }

    var hasActiveFilters: Bool { !activeFilters.isEmpty }

    func toggleFilter(_ filter: ActivityFilter) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
    }

    func clearFilters() {
        activeFilters.removeAll()
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        let tab = selectedTab

        isLoading = true
        errorMessage = nil

        do {
            let result = try await service.fetch(tab: tab)
            guard generation == loadGeneration, tab == selectedTab else { return }
            activities = result
        } catch {
            guard generation == loadGeneration, tab == selectedTab else { return }
            errorMessage = error.localizedDescription
        }

        if generation == loadGeneration {
            isLoading = false
        }
    }

    func select(_ tab: ActivityTab) async {
        guard selectedTab != tab else { return }
        selectedTab = tab
        activeFilters.removeAll()
        activities = []
        await load()
    }
}
