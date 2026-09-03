import SwiftUI

struct LogView: View {
    @StateObject private var vm = LogViewModel()
    @State private var selectedMovie: Movie?
    @State private var recentMovies: [Movie] = []

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchField
                    content
                }
            }
            .navigationTitle("Add a Film")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task(id: vm.query) {
                await vm.search()
            }
            .sheet(item: $selectedMovie) { movie in
                LogEntryView(movie: movie) {
                    addRecent(movie)
                    selectedMovie = nil
                    vm.clear()
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)

            TextField("Name of film", text: $vm.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)

            if !vm.query.isEmpty {
                Button {
                    vm.clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.secondaryBackground)
    }

    @ViewBuilder
    private var content: some View {
        if vm.isSearching {
            Spacer()
            ProgressView()
                .tint(AppTheme.green)
            Spacer()
        } else if let error = vm.errorMessage {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(AppTheme.orange)
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
            Spacer()
        } else if !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            movieResults
        } else {
            recentContent
        }
    }

    private var movieResults: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if vm.movies.isEmpty {
                    EmptyStateView(
                        icon: "film",
                        title: "No films found",
                        subtitle: "Try another title, director, actor or genre."
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(vm.movies) { movie in
                        Button {
                            selectedMovie = movie
                        } label: {
                            MovieSearchRow(movie: movie)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(Color.white.opacity(0.07))
                            .padding(.leading, 82)
                    }
                }
            }
        }
    }

    private var recentContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("RECENT SEARCHES")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 10)

                if recentMovies.isEmpty {
                    Text("Search for a film to log it to your diary.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                } else {
                    ForEach(recentMovies) { movie in
                        Button {
                            selectedMovie = movie
                        } label: {
                            HStack {
                                Text(movie.title)
                                    .foregroundStyle(.white)
                                Spacer()
                                if let year = movie.releaseYear {
                                    Text(String(year))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(Color.white.opacity(0.07))
                    }
                }
            }
        }
    }

    private func addRecent(_ movie: Movie) {
        recentMovies.removeAll { $0.id == movie.id }
        recentMovies.insert(movie, at: 0)
        if recentMovies.count > 10 {
            recentMovies.removeLast(recentMovies.count - 10)
        }
    }
}

private struct MovieSearchRow: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: 12) {
            PosterView(url: movie.posterUrl, width: 52, height: 76)

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let year = movie.releaseYear {
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                if let director = movie.director, !director.isEmpty {
                    Text(director)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
