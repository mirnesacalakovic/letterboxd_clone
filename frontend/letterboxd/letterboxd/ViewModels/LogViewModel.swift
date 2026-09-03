import Foundation
internal import Combine

extension Notification.Name {
    static let diaryDidChange = Notification.Name("diaryDidChange")
}

@MainActor
final class LogViewModel: ObservableObject {
    @Published var query = ""
    @Published var movies: [Movie] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    func search() async {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanQuery.isEmpty else {
            movies = []
            errorMessage = nil
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            try await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            movies = try await MovieService.shared.search(cleanQuery)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    func clear() {
        query = ""
        movies = []
        errorMessage = nil
    }
}

@MainActor
final class LogEntryViewModel: ObservableObject {
    let movie: Movie

    @Published var watchedDate = Date()
    @Published var rating: Double = 0
    @Published var liked = false
    @Published var reviewText = ""
    @Published var tagsText = ""
    @Published var isRewatch = false
    @Published var isSpoiler = false
    @Published var commentsAllowed = true
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didSave = false
    @Published var canSave = false

    private var hasLoadedState = false

    init(movie: Movie) {
        self.movie = movie
    }

    func loadState() async {
        guard !hasLoadedState else { return }
        hasLoadedState = true
        isLoading = true
        errorMessage = nil

        do {
            let state = try await LogService.shared.state(movieId: movie.id)
            rating = state.rating ?? 0
            liked = state.liked
            // Letterboxd's wording is “I've seen this film before”. If the
            // backend already knows it as watched, a new log is naturally a rewatch.
            isRewatch = state.hasWatched
            canSave = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        let cleanReview = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = parsedTags

        let request = LogFilmRequest(
            movieId: movie.id,
            watchedDate: Self.apiDateFormatter.string(from: watchedDate),
            rating: rating > 0 ? rating : nil,
            liked: liked,
            review: cleanReview,
            tags: tags,
            isRewatch: isRewatch,
            isSpoiler: isSpoiler,
            commentsAllowed: commentsAllowed
        )

        do {
            try await LogService.shared.log(request)
            NotificationCenter.default.post(name: .diaryDidChange, object: nil)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func clearRating() {
        rating = 0
    }

    private var parsedTags: [String] {
        var seen = Set<String>()
        return tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
            .prefix(10)
            .map { String($0.prefix(30)) }
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
