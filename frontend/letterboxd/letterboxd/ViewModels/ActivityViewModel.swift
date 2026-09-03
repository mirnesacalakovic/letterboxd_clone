import Foundation
internal import Combine

@MainActor
final class ActivityViewModel: ObservableObject {
    @Published var selectedTab: ActivityTab = .friends
    @Published private(set) var activities: [ActivityItem] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: ActivityService
    private var loadGeneration = 0

    init(service: ActivityService = .shared) {
        self.service = service
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
        activities = []
        await load()
    }
}
