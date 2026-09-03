import Foundation

final class ActivityService {
    static let shared = ActivityService()
    private init() {}

    func fetch(tab: ActivityTab, limit: Int = 50, offset: Int = 0) async throws -> [ActivityItem] {
        let response: ActivityResponse = try await APIClient.shared.request(
            path: "/feed?tab=\(tab.rawValue)&limit=\(limit)&offset=\(offset)",
            method: .get
        )
        return response.activities
    }
}
