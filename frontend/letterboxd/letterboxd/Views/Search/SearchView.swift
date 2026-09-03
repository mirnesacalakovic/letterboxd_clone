import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchHeader

                    if vm.trimmedQuery.isEmpty {
                        if searchFocused {
                            activeSearchEmptyState
                        } else {
                            browseContent
                        }
                    } else {
                        resultsContent
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            // task(id:) is the live-search trigger. Every keystroke cancels
            // the previous debounce task and starts a new one automatically.
            .task(id: vm.query) {
                await vm.liveSearch()
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: 14) {
            if !searchFocused && vm.query.isEmpty {
                Text("Search")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }

            HStack(spacing: 12) {
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(searchFocused ? Color(hex: "#8EA5B8") : Color(hex: "#C6D3DF"))

                    TextField(
                        "",
                        text: $vm.query,
                        prompt: Text("Find films, cast + crew, members…")
                            .foregroundStyle(Color(hex: "#9CB0C3"))
                    )
                    .focused($searchFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .foregroundStyle(searchFocused ? Color(hex: "#26384A") : .white)
                    .tint(Color(hex: "#87A9C5"))
                    .onSubmit {
                        Task { await vm.searchImmediately() }
                    }

                    if !vm.query.isEmpty {
                        Button {
                            vm.clear()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 19))
                                .foregroundStyle(Color(hex: "#8DA5B8"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(searchFocused ? Color(hex: "#D8D8DA") : Color(hex: "#607083"))
                .clipShape(RoundedRectangle(cornerRadius: 11))

                if searchFocused {
                    Button("Cancel") {
                        vm.clear()
                        searchFocused = false
                    }
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "#AABDCF"))
                }
            }
            .padding(.horizontal, 18)

            if searchFocused || !vm.query.isEmpty {
                searchCategoryTabs
            }
        }
        .padding(.top, 8)
        .padding(.bottom, searchFocused || !vm.query.isEmpty ? 12 : 18)
        .background(Color.black)
    }

    private var searchCategoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SearchCategory.allCases) { category in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            vm.selectedCategory = category
                        }
                    } label: {
                        Text(category.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(
                                vm.selectedCategory == category
                                    ? Color.white
                                    : Color(hex: "#96A8B9")
                            )
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(
                                vm.selectedCategory == category
                                    ? AppTheme.green
                                    : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private var activeSearchEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SEARCH")
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.secondaryText)

            Text("Start typing to search \(vm.selectedCategory.title.lowercased()).")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 32)
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

    // MARK: - Results

    @ViewBuilder
    private var resultsContent: some View {
        if vm.isLoading && vm.rawMovies.isEmpty && vm.members.isEmpty {
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
        } else {
            ZStack(alignment: .top) {
                selectedResults

                if vm.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(AppTheme.green)
                        .padding(.top, 8)
                }
            }
        }
    }

    @ViewBuilder
    private var selectedResults: some View {
        switch vm.selectedCategory {
        case .films:
            if vm.films.isEmpty {
                noResults("No film titles contain “\(vm.trimmedQuery)”.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.films) { movie in
                            NavigationLink {
                                MovieDetailView(movie: movie)
                            } label: {
                                SearchMovieResultRow(movie: movie, query: vm.trimmedQuery)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 112)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }

        case .castCrew:
            if vm.castCrew.isEmpty {
                noResults("No cast or crew names contain “\(vm.trimmedQuery)”.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.castCrew) { person in
                            NavigationLink {
                                SearchPersonFilmsView(person: person)
                            } label: {
                                SearchCastCrewResultRow(person: person)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 82)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }

        case .members:
            if vm.members.isEmpty {
                noResults("No member usernames contain “\(vm.trimmedQuery)”.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
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
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func noResults(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.secondaryText)
            Text("No results")
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(28)
    }
}

private struct SearchMovieResultRow: View {
    let movie: Movie
    let query: String

    var body: some View {
        HStack(spacing: 18) {
            PosterView(
                url: movie.posterUrl,
                width: 74,
                height: 111
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(movie.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if let year = movie.releaseYear {
                        Text(String(year))
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                if let director = movie.director, !director.isEmpty {
                    Text("Directed by \(director)")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

private struct SearchCastCrewResultRow: View {
    let person: SearchCastCrewPerson

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#2B3741"))

                Text(String(person.name.prefix(1)).uppercased())
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(hex: "#B8C8D5"))
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Text("\(person.roleText) · \(person.filmCountText)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                let titles = person.movies.prefix(2).map(\.title).joined(separator: ", ")
                if !titles.isEmpty {
                    Text(titles)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#8398AA"))
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.25))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

private struct SearchPersonFilmsView: View {
    let person: SearchCastCrewPerson

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(person.name)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)

                            Text("\(person.roleText) · \(person.filmCountText)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(18)

                    ForEach(person.movies) { movie in
                        NavigationLink {
                            MovieDetailView(movie: movie)
                        } label: {
                            SearchMovieResultRow(movie: movie, query: "")
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.leading, 112)
                    }
                }
            }
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
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
