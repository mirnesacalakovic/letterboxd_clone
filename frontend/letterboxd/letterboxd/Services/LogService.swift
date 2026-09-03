import Foundation

final class LogService {
    static let shared = LogService()
    private init() {}

    func state(movieId: Int) async throws -> LogState {
        let response: LogStateEnvelope = try await APIClient.shared.request(
            path: "/log/\(movieId)",
            method: .get,
            requiresAuth: true
        )
        return response.state
    }

    func log(_ request: LogFilmRequest) async throws {
        let _: LogSaveResponse = try await APIClient.shared.request(
            path: "/log",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }
}
