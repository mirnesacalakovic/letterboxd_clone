import Foundation
internal import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var movies: [Movie] = []
    @Published var members: [ProfilePerson] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false

    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            movies = []
            members = []
            errorMessage = nil
            hasSearched = false
            return
        }

        isLoading = true
        errorMessage = nil
        hasSearched = true

        do {
            async let movieResults = MovieService.shared.search(q)
            async let memberResults = UserService.shared.searchUsers(q)
            let results = try await (movieResults, memberResults)
            movies = results.0
            members = results.1
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clear() {
        query = ""
        movies = []
        members = []
        errorMessage = nil
        hasSearched = false
    }
}
