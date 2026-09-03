import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchHeader

                    if vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.hasSearched {
                        browseContent
                    } else {
                        resultsContent
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var searchHeader: some View {
        VStack(spacing: 18) {
            Text("Search")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color(hex: "#C6D3DF"))

                TextField(
                    "Find films, cast + crew, members, reviews…",
                    text: $vm.query
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(.white)
                .tint(AppTheme.blue)
                .onSubmit {
                    Task { await vm.search() }
                }

                if !vm.query.isEmpty {
                    Button {
                        vm.clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 48)
            .background(Color(hex: "#607083"))
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .padding(.horizontal, 18)
        }
        .padding(.top, 8)
        .padding(.bottom, 18)
        .background(Color.black)
    }

    private var browseContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Browse by")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.top, 28)
                    .padding(.bottom, 12)

                SearchBrowseRow(title: "Release date") {
                    SearchReleaseDateView()
                }

                SearchBrowseRow(title: "Genre, country or language") {
                    SearchGenreView()
                }

                SearchBrowseRow(title: "Service") {
                    SearchInfoView(
                        title: "Service",
                        heading: "Where to watch",
                        paragraphs: [
                            "Browse films by streaming service and availability.",
                            "Favorite services can be used to focus film discovery on the platforms you use most."
                        ]
                    )
                }

                SearchBrowseRow(title: "Letterboxd Video Store") {
                    SearchInfoView(
                        title: "Video Store",
                        heading: "Letterboxd Video Store",
                        paragraphs: [
                            "A curated rental store built around film discovery, with no monthly fee.",
                            "Rent individual films and watch on supported phones, browsers and televisions."
                        ]
                    )
                }

                SearchBrowseRow(title: "Most popular") {
                    SearchMovieGridView(
                        title: "Most popular",
                        mode: .sort("popular", 120)
                    )
                }

                SearchBrowseRow(title: "Highest rated") {
                    SearchMovieGridView(
                        title: "Highest rated",
                        mode: .sort("rating", 120)
                    )
                }

                SearchBrowseRow(title: "Most anticipated") {
                    SearchMovieGridView(
                        title: "Most anticipated",
                        mode: .sort("newest", 120)
                    )
                }

                SearchBrowseRow(title: "Top 500 narrative features") {
                    SearchMovieGridView(
                        title: "Top 500 narrative features",
                        mode: .sort("rating", 500)
                    )
                }

                SearchBrowseRow(title: "Featured lists") {
                    SearchListsBrowseView(
                        title: "Featured lists",
                        sortBy: "movieCount"
                    )
                }

                SearchBrowseRow(title: "Official lists") {
                    SearchListsBrowseView(
                        title: "Official lists",
                        sortBy: "newest"
                    )
                }

                Text("Letterboxd.com")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.top, 48)
                    .padding(.bottom, 12)

                SearchInfoRow(
                    title: "New here?",
                    heading: "Welcome to Letterboxd",
                    paragraphs: [
                        "Keep a diary of the films you watch, rate and review them, build lists and maintain a watchlist.",
                        "Follow other members to discover what they are watching and talking about."
                    ]
                )

                SearchInfoRow(
                    title: "Frequent questions",
                    heading: "Frequent questions",
                    paragraphs: [
                        "Film information is sourced from TMDB. Ratings use a five-star scale in half-star increments.",
                        "Diary entries are dated watches; marking a film watched without logging it does not need a diary date."
                    ]
                )

                SearchInfoRow(
                    title: "About subscriptions",
                    heading: "Subscriptions",
                    paragraphs: [
                        "Pro removes third-party ads and adds personalized stats, favorite streaming services, activity filters, watchlist availability notifications and more.",
                        "Patron includes Pro benefits plus preferred posters and backdrops, additional customization and early access to selected features."
                    ]
                )

                SearchInfoRow(
                    title: "Journal / Editorial",
                    heading: "Journal",
                    paragraphs: [
                        "Letterboxd Journal features interviews, festival coverage, essays, platform news, podcasts and Year in Review stories."
                    ]
                )

                SearchInfoRow(
                    title: "Showdown challenges",
                    heading: "Showdown",
                    paragraphs: [
                        "A recurring community challenge: Letterboxd sets a theme, members create ranked lists, and the results are combined into a community consensus."
                    ]
                )

                SearchInfoRow(
                    title: "Year in Review",
                    heading: "Year in Review",
                    paragraphs: [
                        "An annual look at the films, ratings, diary entries, reviews, lists and viewing trends that defined the year across the Letterboxd community."
                    ]
                )

                SearchInfoRow(
                    title: "Gift Guide",
                    heading: "Gift Guide",
                    paragraphs: [
                        "Gift subscriptions and film-lover picks collected for members looking for something to give or discover."
                    ]
                )

                SearchInfoRow(
                    title: "Merch",
                    heading: "Merch",
                    paragraphs: [
                        "Letterboxd-branded apparel and film-community merchandise."
                    ]
                )

                SearchInfoRow(
                    title: "Contact",
                    heading: "Contact",
                    paragraphs: [
                        "Use support for account, subscription and app questions, or report film-data issues through the relevant film page."
                    ]
                )

                SearchInfoRow(
                    title: "Social accounts / Follow us",
                    heading: "Follow Letterboxd",
                    paragraphs: [
                        "Find Letterboxd community highlights, editorial picks and platform updates across its official social channels."
                    ]
                )

                SearchInfoRow(
                    title: "Terms of use / Community policy",
                    heading: "Terms and Community Policy",
                    paragraphs: [
                        "Community participation is expected to remain respectful. Harassment, spam and abusive behavior are not part of constructive film discussion."
                    ]
                )
            }
            .padding(.bottom, 34)
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        if vm.isLoading {
            Spacer()
            ProgressView()
                .tint(AppTheme.green)
            Spacer()
        } else if let error = vm.errorMessage {
            Spacer()
            EmptyStateView(
                icon: "exclamationmark.triangle",
                title: "Search failed",
                subtitle: error
            )
            .padding()
            Spacer()
        } else if vm.movies.isEmpty && vm.members.isEmpty {
            Spacer()
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No results",
                subtitle: "Try another film, filmmaker, cast member or username."
            )
            .padding()
            Spacer()
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !vm.movies.isEmpty {
                        SearchResultsHeading("FILMS, CAST + CREW")

                        ForEach(vm.movies) { movie in
                            NavigationLink {
                                MovieDetailView(movie: movie)
                            } label: {
                                SearchMovieResultRow(movie: movie)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 94)
                        }
                    }

                    if !vm.members.isEmpty {
                        SearchResultsHeading("MEMBERS")
                            .padding(.top, 18)

                        ForEach(vm.members) { member in
                            NavigationLink {
                                ProfileView(userId: member.id, isOwnProfile: false)
                            } label: {
                                SearchMemberResultRow(member: member)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 82)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
}

private struct SearchBrowseRow<Destination: View>: View {
    let title: String
    let destination: Destination

    init(title: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.destination = destination()
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#516A7F"))
            }
            .frame(minHeight: 48)
            .padding(.horizontal, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Divider()
            .overlay(Color(hex: "#2D3841"))
            .padding(.leading, 18)
    }
}

private struct SearchInfoRow: View {
    let title: String
    let heading: String
    let paragraphs: [String]

    var body: some View {
        SearchBrowseRow(title: title) {
            SearchInfoView(
                title: title,
                heading: heading,
                paragraphs: paragraphs
            )
        }
    }
}

private struct SearchInfoView: View {
    let title: String
    let heading: String
    let paragraphs: [String]

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(heading)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineSpacing(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
    }
}

private struct SearchResultsHeading: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .tracking(0.8)
            .foregroundStyle(AppTheme.secondaryText)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 8)
    }
}

private struct SearchMovieResultRow: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: 14) {
            PosterView(
                url: movie.posterUrl,
                width: 62,
                height: 92
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(movie.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if let year = movie.releaseYear {
                        Text(String(year))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                if let director = movie.director, !director.isEmpty {
                    Text("Directed by \(director)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }

                if let rating = movie.averageRating {
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                        Text(String(format: "%.1f", rating))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.green)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.25))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

private struct SearchMemberResultRow: View {
    let member: ProfilePerson

    var body: some View {
        HStack(spacing: 13) {
            AsyncImage(url: APIConfig.mediaURL(for: member.avatarUrl)) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(member.username)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                if let bio = member.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.25))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

private enum SearchMovieBrowseMode {
    case sort(String, Int)
    case decade(Int)
    case genre(String)
}

private struct SearchMovieGridView: View {
    let title: String
    let mode: SearchMovieBrowseMode

    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(AppTheme.green)
            } else if let errorMessage {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn’t load films",
                    subtitle: errorMessage
                )
                .padding()
            } else if movies.isEmpty {
                EmptyStateView(
                    icon: "film",
                    title: "No films",
                    subtitle: "Nothing to show here yet."
                )
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 96), spacing: 10)],
                        spacing: 14
                    ) {
                        ForEach(movies) { movie in
                            NavigationLink {
                                MovieDetailView(movie: movie)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    PosterView(
                                        url: movie.posterUrl,
                                        width: 105,
                                        height: 157
                                    )

                                    Text(movie.title)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .task { await load() }
    }

    @MainActor
    private func load() async {
        guard isLoading else { return }

        do {
            switch mode {
            case .sort(let sortBy, let limit):
                movies = try await MovieService.shared.browse(
                    sortBy: sortBy,
                    limit: limit
                )

            case .decade(let decade):
                movies = try await MovieService.shared.browse(
                    decade: decade,
                    sortBy: "popular",
                    limit: 120
                )

            case .genre(let genre):
                movies = try await MovieService.shared.search(genre)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

private struct SearchReleaseDateView: View {
    private let decades = Array(stride(from: 2020, through: 1920, by: -10))

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(decades, id: \.self) { decade in
                        NavigationLink {
                            SearchMovieGridView(
                                title: "\(decade)s",
                                mode: .decade(decade)
                            )
                        } label: {
                            HStack {
                                Text("\(decade)s")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.secondaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color(hex: "#516A7F"))
                            }
                            .padding(.horizontal, 18)
                            .frame(height: 52)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(Color(hex: "#2D3841"))
                            .padding(.leading, 18)
                    }
                }
            }
        }
        .navigationTitle("Release date")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
    }
}

private struct SearchGenreView: View {
    private let genres = [
        "Action", "Adventure", "Animation", "Comedy", "Crime", "Documentary",
        "Drama", "Family", "Fantasy", "History", "Horror", "Music", "Mystery",
        "Romance", "Science Fiction", "Thriller", "War", "Western"
    ]

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(genres, id: \.self) { genre in
                        NavigationLink {
                            SearchMovieGridView(
                                title: genre,
                                mode: .genre(genre)
                            )
                        } label: {
                            HStack {
                                Text(genre)
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.secondaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color(hex: "#516A7F"))
                            }
                            .padding(.horizontal, 18)
                            .frame(height: 52)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(Color(hex: "#2D3841"))
                            .padding(.leading, 18)
                    }
                }
            }
        }
        .navigationTitle("Genre")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
    }
}

private struct SearchListsBrowseView: View {
    let title: String
    let sortBy: String

    @State private var lists: [MovieListSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(AppTheme.green)
            } else if let errorMessage {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn’t load lists",
                    subtitle: errorMessage
                )
                .padding()
            } else if lists.isEmpty {
                EmptyStateView(
                    icon: "rectangle.stack",
                    title: "No lists",
                    subtitle: "Nothing to show here yet."
                )
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(lists) { list in
                            ProfileListPreviewRow(list: list)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .task { await load() }
    }

    @MainActor
    private func load() async {
        guard isLoading else { return }

        do {
            lists = try await UserService.shared.discoverLists(sortBy: sortBy)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
