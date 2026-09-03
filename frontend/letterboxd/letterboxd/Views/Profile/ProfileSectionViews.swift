import SwiftUI

enum ProfileSection: String, Hashable, Identifiable {
    case films = "Films"
    case diary = "Diary"
    case reviews = "Reviews"
    case lists = "Lists"
    case watchlist = "Watchlist"
    case likes = "Likes"
    case tags = "Tags"
    case following = "Following"
    case followers = "Followers"
    case stats = "Stats"

    var id: String { rawValue }
}

struct ProfileSectionView: View {
    let section: ProfileSection
    let userId: Int
    let isOwnProfile: Bool

    @State private var loading = true
    @State private var errorMessage: String?
    @State private var watched: [WatchedMovieItem] = []
    @State private var diary: [DiaryEntry] = []
    @State private var reviews: [UserReviewItem] = []
    @State private var lists: [MovieListSummary] = []
    @State private var watchlist: [WatchlistItem] = []
    @State private var likes: [LikedMovieItem] = []
    @State private var people: [ProfilePerson] = []
    @State private var showCreateList = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            Group {
                if section == .stats {
                    ScrollView { content.padding() }
                } else if loading {
                    ProgressView().tint(AppTheme.green)
                } else if let errorMessage {
                    EmptyStateView(icon: "exclamationmark.triangle", title: "Couldn’t load \(section.rawValue)", subtitle: errorMessage)
                        .padding()
                } else {
                    ScrollView { content.padding() }
                }
            }
        }
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbar {
            if section == .lists && isOwnProfile {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateList = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Create list")
                }
            }
        }
        .sheet(isPresented: $showCreateList) {
            ListEditorView(mode: .create) {
                Task { await reloadLists() }
            }
        }
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .films:
            posterGrid(watched.map { ($0.movieId, $0.title, $0.posterUrl, $0.releaseYear, $0.asMovie) }, emptyTitle: "No films yet", emptyIcon: "film")
        case .diary:
            ProfileDiaryTab(entries: diary)
        case .reviews:
            reviewsContent
        case .lists:
            listsContent
        case .watchlist:
            ProfileWatchlistTab(items: watchlist)
        case .likes:
            posterGrid(likes.map { ($0.movieId, $0.title, $0.posterUrl, $0.releaseYear, $0.asMovie) }, emptyTitle: "No liked films yet", emptyIcon: "heart")
        case .tags:
            tagsContent
        case .following, .followers:
            peopleContent
        case .stats:
            ProfileStatsView(userId: userId)
        }
    }

    private func posterGrid(_ items: [(Int, String, String?, Int?, Movie)], emptyTitle: String, emptyIcon: String) -> some View {
        Group {
            if items.isEmpty {
                EmptyStateView(icon: emptyIcon, title: emptyTitle, subtitle: "Nothing to show here yet.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 10)], spacing: 14) {
                    ForEach(items, id: \.0) { item in
                        NavigationLink(destination: MovieDetailView(movie: item.4)) {
                            VStack(alignment: .leading, spacing: 5) {
                                PosterView(url: item.2, width: 105, height: 157)
                                Text(item.1).font(.caption.bold()).foregroundStyle(.white).lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }

    private var reviewsContent: some View {
        VStack(spacing: 0) {
            if reviews.isEmpty {
                EmptyStateView(icon: "text.bubble", title: "No reviews yet", subtitle: "Reviews will appear here.")
            } else {
                ForEach(reviews) { review in
                    NavigationLink(destination: MovieDetailView(movie: review.asMovie)) {
                        HStack(alignment: .top, spacing: 12) {
                            PosterView(url: review.posterUrl, width: 58, height: 87)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline, spacing: 5) {
                                    Text(review.title).font(.subheadline.bold()).foregroundStyle(.white)
                                    if let year = review.releaseYear { Text(String(year)).font(.caption).foregroundStyle(AppTheme.secondaryText) }
                                }
                                if review.isSpoiler {
                                    Label("Contains spoilers", systemImage: "eye.slash")
                                        .font(.caption2).foregroundStyle(AppTheme.orange)
                                } else {
                                    Text(review.content).font(.caption).foregroundStyle(AppTheme.secondaryText).lineLimit(4)
                                }
                                if review.likeCount > 0 {
                                    Label("\(review.likeCount)", systemImage: "heart.fill")
                                        .font(.caption2).foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    Divider().overlay(AppTheme.cardBackground)
                }
            }
        }
    }

    private var listsContent: some View {
        VStack(spacing: 0) {
            if lists.isEmpty {
                EmptyStateView(
                    icon: "square.stack",
                    title: "No lists yet",
                    subtitle: "Lists will appear here."
                )
            } else {
                ForEach(lists) { list in
                    ProfileListPreviewRow(
                        list: list,
                        canEdit: isOwnProfile,
                        onChanged: {
                            Task { await reloadLists() }
                        }
                    )
                }
            }
        }
    }

    private var tagsContent: some View {
        let taggedFilms = makeTaggedFilms()
        let counts = Dictionary(grouping: taggedFilms.flatMap(\.tags), by: { $0 }).mapValues(\.count)
        let sorted = counts.sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value }
        return VStack(spacing: 0) {
            if sorted.isEmpty {
                EmptyStateView(icon: "tag", title: "No tags yet", subtitle: "Tags added while logging or reviewing films will appear here.")
            } else {
                ForEach(sorted, id: \.key) { item in
                    NavigationLink(destination: ProfileTagMoviesView(tag: item.key, films: taggedFilms)) {
                        HStack {
                            Image(systemName: "tag.fill").foregroundStyle(AppTheme.secondaryText)
                            Text(item.key).foregroundStyle(.white)
                            Spacer()
                            Text("\(item.value)").foregroundStyle(AppTheme.secondaryText)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(.vertical, 12)
                    }
                    Divider().overlay(AppTheme.cardBackground)
                }
            }
        }
    }

    private func makeTaggedFilms() -> [TaggedProfileFilm] {
        var byMovie: [Int: TaggedProfileFilm] = [:]

        for review in reviews {
            let existing = byMovie[review.movieId]
            let tags = Set((existing?.tags ?? []) + review.tags)
            byMovie[review.movieId] = TaggedProfileFilm(
                movieId: review.movieId,
                title: review.title,
                releaseYear: review.releaseYear,
                posterUrl: review.posterUrl,
                tags: Array(tags),
                reviewText: review.isSpoiler ? nil : review.content,
                isSpoiler: review.isSpoiler
            )
        }

        for entry in diary {
            let existing = byMovie[entry.movieId]
            let tags = Set((existing?.tags ?? []) + entry.tags)
            byMovie[entry.movieId] = TaggedProfileFilm(
                movieId: entry.movieId,
                title: existing?.title ?? entry.title,
                releaseYear: existing?.releaseYear ?? entry.releaseYear,
                posterUrl: existing?.posterUrl ?? entry.posterUrl,
                tags: Array(tags),
                reviewText: existing?.reviewText,
                isSpoiler: existing?.isSpoiler ?? false
            )
        }

        return Array(byMovie.values)
    }

    private var peopleContent: some View {
        VStack(spacing: 0) {
            if people.isEmpty {
                EmptyStateView(icon: "person.2", title: "No members yet", subtitle: "Nothing to show here yet.")
            } else {
                ForEach(people) { person in
                    NavigationLink(destination: ProfileView(userId: person.id, isOwnProfile: false)) {
                        HStack(spacing: 12) {
                            AsyncImage(url: APIConfig.mediaURL(for: person.avatarUrl)) { phase in
                                if case .success(let image) = phase { image.resizable().scaledToFill() }
                                else { Image(systemName: "person.crop.circle.fill").resizable().foregroundStyle(AppTheme.secondaryText) }
                            }
                            .frame(width: 48, height: 48).clipShape(Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(person.username).font(.subheadline.bold()).foregroundStyle(.white)
                                if let bio = person.bio, !bio.isEmpty { Text(bio).font(.caption).foregroundStyle(AppTheme.secondaryText).lineLimit(2) }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(.vertical, 10)
                    }
                    Divider().overlay(AppTheme.cardBackground)
                }
            }
        }
    }

    @MainActor
    private func reloadLists() async {
        guard section == .lists else { return }
        do {
            lists = try await UserService.shared.fetchLists(userId: userId, isOwnProfile: isOwnProfile)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load() async {
        guard loading else { return }
        do {
            switch section {
            case .films:
                watched = try await UserService.shared.fetchWatched(userId: userId, isOwnProfile: isOwnProfile)
            case .diary:
                diary = try await UserService.shared.fetchDiary(userId: userId, isOwnProfile: isOwnProfile)
            case .reviews:
                reviews = try await UserService.shared.fetchReviews(userId: userId)
            case .tags:
                async let loadedReviews = UserService.shared.fetchReviews(userId: userId)
                async let loadedDiary = UserService.shared.fetchDiary(userId: userId, isOwnProfile: isOwnProfile)
                (reviews, diary) = try await (loadedReviews, loadedDiary)
            case .lists:
                lists = try await UserService.shared.fetchLists(userId: userId, isOwnProfile: isOwnProfile)
            case .watchlist:
                watchlist = try await UserService.shared.fetchWatchlist(userId: userId, isOwnProfile: isOwnProfile)
            case .likes:
                likes = try await UserService.shared.fetchLikes(userId: userId)
            case .followers:
                people = try await UserService.shared.fetchFollowers(userId: userId)
            case .following:
                people = try await UserService.shared.fetchFollowing(userId: userId)
            case .stats:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}

struct MovieListDetailView: View {
    let listId: Int
    let title: String
    let canEdit: Bool
    let onChanged: (() -> Void)?

    @State private var detail: MovieListDetail?
    @State private var errorMessage: String?
    @State private var showEditor = false

    init(
        listId: Int,
        title: String,
        canEdit: Bool = false,
        onChanged: (() -> Void)? = nil
    ) {
        self.listId = listId
        self.title = title
        self.canEdit = canEdit
        self.onChanged = onChanged
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let description = detail.description, !description.isEmpty {
                            Text(description)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        if detail.movies.isEmpty {
                            EmptyStateView(
                                icon: "film",
                                title: "No films yet",
                                subtitle: canEdit ? "Tap Edit to add films to this list." : "This list does not contain any films yet."
                            )
                            .padding(.top, 40)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 95), spacing: 10)],
                                spacing: 14
                            ) {
                                ForEach(detail.movies) { item in
                                    NavigationLink(destination: MovieDetailView(movie: item.asMovie)) {
                                        VStack(alignment: .leading, spacing: 5) {
                                            PosterView(url: item.posterUrl, width: 105, height: 157)
                                            Text(item.title)
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else if let errorMessage {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn’t load list",
                    subtitle: errorMessage
                )
                .padding()
            } else {
                ProgressView().tint(AppTheme.green)
            }
        }
        .navigationTitle(detail?.name ?? title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbar {
            if canEdit, detail != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showEditor = true
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.green)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let detail {
                ListEditorView(mode: .edit(listId: listId, detail: detail)) {
                    Task {
                        await reload()
                        onChanged?()
                    }
                }
            }
        }
        .task {
            if detail == nil {
                await reload()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .listsDidChange)) { _ in
            guard canEdit else { return }
            Task { await reload() }
        }
    }

    @MainActor
    private func reload() async {
        do {
            detail = try await UserService.shared.fetchListDetail(id: listId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


struct TaggedProfileFilm: Identifiable {
    let movieId: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?
    let tags: [String]
    let reviewText: String?
    let isSpoiler: Bool

    var id: Int { movieId }
    var asMovie: Movie { Movie(id: movieId, title: title, releaseYear: releaseYear, posterUrl: posterUrl) }
}

struct ProfileTagMoviesView: View {
    let tag: String
    let films: [TaggedProfileFilm]

    private var taggedFilms: [TaggedProfileFilm] {
        films
            .filter { film in
                film.tags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame }
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if taggedFilms.isEmpty {
                        EmptyStateView(
                            icon: "tag",
                            title: "No films",
                            subtitle: "No films are tagged with \(tag)."
                        )
                        .padding(.top, 50)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                            Text("\(taggedFilms.count) \(taggedFilms.count == 1 ? "FILM" : "FILMS")")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.bottom, 8)

                        ForEach(taggedFilms) { film in
                            NavigationLink(destination: MovieDetailView(movie: film.asMovie)) {
                                HStack(alignment: .top, spacing: 12) {
                                    PosterView(url: film.posterUrl, width: 68, height: 102)
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                                            Text(film.title)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(.white)
                                            if let year = film.releaseYear {
                                                Text(String(year))
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.secondaryText)
                                            }
                                        }

                                        if film.isSpoiler {
                                            Label("Contains spoilers", systemImage: "eye.slash")
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.orange)
                                        } else if let review = film.reviewText, !review.isEmpty {
                                            Text(review)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.secondaryText)
                                                .lineLimit(3)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .padding(.top, 4)
                                }
                                .padding(.vertical, 10)
                            }
                            Divider().overlay(AppTheme.cardBackground)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(tag)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
    }
}


struct ProfileStatsView: View {
    let userId: Int
    @State private var stats: StatsData?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if let stats {
                HStack(spacing: 10) {
                    statCard(value: "\(stats.summary.moviesWatched)", label: "FILMS")
                    statCard(value: runtimeText(stats.summary.totalRuntimeMinutes), label: "HOURS")
                    statCard(value: stats.summary.averageRating.map { String(format: "%.2f", $0) } ?? "—", label: "AVG RATING")
                }

                RatingsHistogramView(distribution: stats.ratingsDistribution, averageRating: stats.summary.averageRating)

                if let genres = stats.topGenres, !genres.isEmpty {
                    ranking("TOP GENRES", genres)
                }
                if let directors = stats.topDirectors, !directors.isEmpty {
                    ranking("TOP DIRECTORS", directors)
                }
            } else if let errorMessage {
                EmptyStateView(icon: "chart.bar", title: "Couldn’t load stats", subtitle: errorMessage)
            } else {
                ProgressView().tint(AppTheme.green).frame(maxWidth: .infinity).padding(.top, 60)
            }
        }
        .task {
            do { stats = try await UserService.shared.fetchStats(userId: userId) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.title3.bold()).foregroundStyle(.white)
            Text(label).font(.caption2.bold()).foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func ranking(_ title: String, _ items: [StatsNamedCount]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.caption.bold()).foregroundStyle(AppTheme.secondaryText).padding(.bottom, 8)
            ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                HStack {
                    Text("\(index + 1)").foregroundStyle(AppTheme.secondaryText).frame(width: 24, alignment: .leading)
                    Text(item.name).foregroundStyle(.white)
                    Spacer()
                    Text("\(item.count)").foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.vertical, 10)
                Divider().overlay(AppTheme.cardBackground)
            }
        }
    }

    private func runtimeText(_ minutes: Int) -> String {
        String(format: "%.0f", Double(minutes) / 60.0)
    }
}
