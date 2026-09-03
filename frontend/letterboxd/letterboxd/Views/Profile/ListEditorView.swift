import SwiftUI

struct ListEditorView: View {
    enum Mode {
        case create
        case edit(listId: Int, detail: MovieListDetail)
    }

    let mode: Mode
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var listDescription: String
    @State private var isPublic: Bool
    @State private var currentMovies: [MovieListMovie]
    @State private var movieQuery = ""
    @State private var searchResults: [Movie] = []
    @State private var isSearching = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var pendingSearchTask: Task<Void, Never>?

    init(mode: Mode, onSaved: @escaping () -> Void = {}) {
        self.mode = mode
        self.onSaved = onSaved

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _listDescription = State(initialValue: "")
            _isPublic = State(initialValue: true)
            _currentMovies = State(initialValue: [])
        case .edit(_, let detail):
            _name = State(initialValue: detail.name)
            _listDescription = State(initialValue: detail.description ?? "")
            _isPublic = State(initialValue: detail.isPublic)
            _currentMovies = State(initialValue: detail.movies)
        }
    }

    private var listId: Int? {
        if case .edit(let id, _) = mode { return id }
        return nil
    }

    private var isEditing: Bool { listId != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        detailsSection

                        if isEditing {
                            filmsSection
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle(isEditing ? "Edit list" : "New list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.secondaryText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Create") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.green)
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("LIST DETAILS")

            VStack(spacing: 0) {
                TextField("List name", text: $name)
                    .textInputAutocapitalization(.sentences)
                    .foregroundStyle(.white)
                    .padding(14)

                Divider().overlay(Color.white.opacity(0.08))

                TextField("Description", text: $listDescription, axis: .vertical)
                    .lineLimit(3...7)
                    .foregroundStyle(.white)
                    .padding(14)

                Divider().overlay(Color.white.opacity(0.08))

                Toggle(isOn: $isPublic) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Public list")
                            .foregroundStyle(.white)
                        Text(isPublic ? "Anyone can view this list" : "Only you can view this list")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .tint(AppTheme.green)
                .padding(14)
            }
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
    }

    private var filmsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("FILMS")
                Spacer()
                Text("\(currentMovies.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if !currentMovies.isEmpty {
                VStack(spacing: 0) {
                    ForEach(currentMovies) { item in
                        HStack(spacing: 11) {
                            PosterView(url: item.posterUrl, width: 40, height: 60)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                if let year = item.releaseYear {
                                    Text(String(year))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }

                            Spacer()

                            Button {
                                Task { await remove(item) }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(AppTheme.orange)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                        Divider().overlay(Color.white.opacity(0.08))
                    }
                }
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.secondaryText)

                    TextField("Add a film…", text: $movieQuery)
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: movieQuery) { _, _ in
                            scheduleMovieSearch()
                        }

                    if !movieQuery.isEmpty {
                        Button {
                            movieQuery = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 9))

                if isSearching {
                    ProgressView()
                        .tint(AppTheme.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                if !searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(searchResults.filter { movie in
                            !currentMovies.contains { $0.movieId == movie.id }
                        }.prefix(8)) { movie in
                            HStack(spacing: 10) {
                                PosterView(url: movie.posterUrl, width: 38, height: 57)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(movie.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    if let year = movie.releaseYear {
                                        Text(String(year))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }

                                Spacer()

                                Button {
                                    Task { await add(movie) }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppTheme.green)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)

                            Divider().overlay(Color.white.opacity(0.08))
                        }
                    }
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(0.7)
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func scheduleMovieSearch() {
        pendingSearchTask?.cancel()
        let query = movieQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        pendingSearchTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await searchMovies(query)
        }
    }

    @MainActor
    private func searchMovies(_ query: String) async {
        guard query == movieQuery.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        isSearching = true
        defer { isSearching = false }

        do {
            let results = try await MovieService.shared.search(query)
            guard query == movieQuery.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            searchResults = results
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !isSaving else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            if let listId {
                _ = try await UserService.shared.updateList(
                    id: listId,
                    name: trimmedName,
                    description: listDescription,
                    isPublic: isPublic
                )
            } else {
                _ = try await UserService.shared.createList(
                    name: trimmedName,
                    description: listDescription,
                    isPublic: isPublic
                )
            }

            NotificationCenter.default.post(name: .listsDidChange, object: nil)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func add(_ movie: Movie) async {
        guard let listId else { return }
        errorMessage = nil

        do {
            try await UserService.shared.addMovie(listId: listId, movieId: movie.id)
            currentMovies.append(
                MovieListMovie(
                    movieId: movie.id,
                    title: movie.title,
                    releaseYear: movie.releaseYear,
                    posterUrl: movie.posterUrl
                )
            )
            searchResults.removeAll { $0.id == movie.id }
            NotificationCenter.default.post(name: .listsDidChange, object: nil)
            onSaved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func remove(_ movie: MovieListMovie) async {
        guard let listId else { return }
        errorMessage = nil

        do {
            try await UserService.shared.removeMovie(listId: listId, movieId: movie.movieId)
            currentMovies.removeAll { $0.movieId == movie.movieId }
            NotificationCenter.default.post(name: .listsDidChange, object: nil)
            onSaved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension Notification.Name {
    static let listsDidChange = Notification.Name("listsDidChange")
}
