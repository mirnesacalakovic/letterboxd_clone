import Foundation
internal import Combine

// Search is intentionally split into the same kinds of results the user sees
// in Letterboxd: films, people who worked on films, and members.
enum SearchCategory: String, CaseIterable, Identifiable {
    case films
    case castCrew
    case members

    var id: String { rawValue }

    var title: String {
        switch self {
        case .films: return "Films"
        case .castCrew: return "Cast + Crew"
        case .members: return "Members"
        }
    }
}

struct SearchCastCrewPerson: Identifiable {
    let name: String
    let isDirector: Bool
    let isCast: Bool
    let movies: [Movie]

    var id: String { name.lowercased() }

    var roleText: String {
        if isDirector && isCast { return "Cast · Director" }
        if isDirector { return "Director" }
        return "Cast"
    }

    var filmCountText: String {
        "\(movies.count) film\(movies.count == 1 ? "" : "s")"
    }
}

private struct SearchPersonAccumulator {
    var name: String
    var isDirector = false
    var isCast = false
    var movies: [Movie] = []
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedCategory: SearchCategory = .films
    @Published private(set) var rawMovies: [Movie] = []
    @Published private(set) var members: [ProfilePerson] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false

    private var searchGeneration = 0

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // The Films tab is TITLE search only. The backend search endpoint also
    // matches directors/cast/genres for other app features, so we narrow the
    // returned candidates here to titles containing the typed string.
    var films: [Movie] {
        let needle = trimmedQuery
        guard !needle.isEmpty else { return [] }

        return rawMovies
            .filter { $0.title.localizedCaseInsensitiveContains(needle) }
            .sorted { lhs, rhs in
                filmRank(lhs.title, query: needle) < filmRank(rhs.title, query: needle)
            }
    }

    // Cast/Crew is derived from the actual director + cast fields already
    // returned by movie search. No fake people or studios are introduced.
    var castCrew: [SearchCastCrewPerson] {
        let needle = trimmedQuery
        guard !needle.isEmpty else { return [] }

        var people: [String: SearchPersonAccumulator] = [:]

        for movie in rawMovies {
            if let director = movie.director,
               director.localizedCaseInsensitiveContains(needle) {
                addPerson(
                    name: director,
                    movie: movie,
                    director: true,
                    cast: false,
                    into: &people
                )
            }

            for actor in movie.cast where actor.localizedCaseInsensitiveContains(needle) {
                addPerson(
                    name: actor,
                    movie: movie,
                    director: false,
                    cast: true,
                    into: &people
                )
            }
        }

        return people.values
            .map {
                SearchCastCrewPerson(
                    name: $0.name,
                    isDirector: $0.isDirector,
                    isCast: $0.isCast,
                    movies: $0.movies.sorted { $0.title < $1.title }
                )
            }
            .sorted { lhs, rhs in
                personRank(lhs.name, query: needle) < personRank(rhs.name, query: needle)
            }
    }

    // Called from .task(id: query). SwiftUI cancels the previous task every
    // time another character is typed, which gives us reliable live search.
    func liveSearch() async {
        let expectedQuery = trimmedQuery

        guard !expectedQuery.isEmpty else {
            resetResults()
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(220))
        } catch {
            return
        }

        guard !Task.isCancelled else { return }
        await performSearch(expectedQuery)
    }

    // Keyboard Search still works, but is no longer required.
    func searchImmediately() async {
        let expectedQuery = trimmedQuery
        guard !expectedQuery.isEmpty else {
            resetResults()
            return
        }
        await performSearch(expectedQuery)
    }

    func clear() {
        query = ""
        resetResults()
    }

    private func performSearch(_ expectedQuery: String) async {
        searchGeneration += 1
        let generation = searchGeneration

        isLoading = true
        errorMessage = nil
        hasSearched = true

        do {
            // Ask for more movie candidates because this same response is used
            // both for title matches and for matching cast/crew names.
            async let movieResults = MovieService.shared.search(expectedQuery, limit: 100)
            async let memberResults = UserService.shared.searchUsers(expectedQuery, limit: 50)

            let (moviesResult, membersResult) = try await (movieResults, memberResults)

            guard generation == searchGeneration,
                  expectedQuery == trimmedQuery,
                  !Task.isCancelled else {
                return
            }

            rawMovies = moviesResult
            members = membersResult
        } catch {
            guard generation == searchGeneration,
                  expectedQuery == trimmedQuery else {
                return
            }
            errorMessage = error.localizedDescription
        }

        if generation == searchGeneration {
            isLoading = false
        }
    }

    private func resetResults() {
        searchGeneration += 1
        rawMovies = []
        members = []
        errorMessage = nil
        hasSearched = false
        isLoading = false
    }

    private func addPerson(
        name: String,
        movie: Movie,
        director: Bool,
        cast: Bool,
        into people: inout [String: SearchPersonAccumulator]
    ) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        let key = cleaned.lowercased()
        var person = people[key] ?? SearchPersonAccumulator(name: cleaned)
        person.isDirector = person.isDirector || director
        person.isCast = person.isCast || cast

        if !person.movies.contains(where: { $0.id == movie.id }) {
            person.movies.append(movie)
        }

        people[key] = person
    }

    private func filmRank(_ title: String, query: String) -> (Int, Int, String) {
        let value = title.lowercased()
        let needle = query.lowercased()

        if value == needle { return (0, 0, value) }
        if value.hasPrefix(needle) { return (1, value.count, value) }

        let position = value.range(of: needle).map {
            value.distance(from: value.startIndex, to: $0.lowerBound)
        } ?? Int.max

        return (2, position, value)
    }

    private func personRank(_ name: String, query: String) -> (Int, Int, String) {
        let value = name.lowercased()
        let needle = query.lowercased()

        if value == needle { return (0, 0, value) }
        if value.hasPrefix(needle) { return (1, value.count, value) }

        let position = value.range(of: needle).map {
            value.distance(from: value.startIndex, to: $0.lowerBound)
        } ?? Int.max

        return (2, position, value)
    }
}
