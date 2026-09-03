import SwiftUI

struct MovieDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var vm: MovieDetailViewModel

    @State private var infoTab: MovieInfoTab = .cast
    @State private var showAllCast = false
    @State private var showFullOverview = false
    @State private var showLogSheet = false

    init(movie: Movie) {
        _vm = StateObject(wrappedValue: MovieDetailViewModel(movie: movie))
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    hero
                    overviewSection
                    ratingsSection
                    userActivityCard
                    watchedBySection
                    statsCards
                    infoSection
                    reviewsSection
                    filmRows
                }
                .padding(.bottom, 24)
            }
            .ignoresSafeArea(edges: .top)

            topBar
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .sheet(isPresented: $showLogSheet) {
            LogEntryView(movie: vm.movie) {
                Task { await vm.refreshAfterLog() }
            }
        }
        .alert("Movie", isPresented: Binding(
            get: { vm.message != nil },
            set: { if !$0 { vm.message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.message ?? "")
        }
    }

    // MARK: - Top / hero

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.42))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                Button {
                    showLogSheet = true
                } label: {
                    Label("Log or review", systemImage: "plus.circle")
                }

                Button {
                    Task { await vm.toggleWatched() }
                } label: {
                    Label(
                        vm.isWatched ? "Remove from watched" : "Mark as watched",
                        systemImage: vm.isWatched ? "eye.slash" : "eye"
                    )
                }

                Button {
                    Task { await vm.toggleWatchlist() }
                } label: {
                    Label(
                        vm.isInWatchlist ? "Remove from watchlist" : "Add to watchlist",
                        systemImage: vm.isInWatchlist ? "bookmark.slash" : "bookmark"
                    )
                }

                Button {
                    Task { await vm.toggleLike() }
                } label: {
                    Label(
                        vm.isLiked ? "Unlike film" : "Like film",
                        systemImage: vm.isLiked ? "heart.slash" : "heart"
                    )
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.42))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    private var hero: some View {
        ZStack(alignment: .bottom) {
            backdrop
                .frame(height: 420)
                .clipped()

            LinearGradient(
                colors: [
                    Color.clear,
                    AppTheme.background.opacity(0.45),
                    AppTheme.background.opacity(0.95),
                    AppTheme.background,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 270)

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(vm.movie.title)
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    if vm.movie.releaseYear != nil || vm.movie.director != nil {
                        VStack(alignment: .leading, spacing: 4) {
                            if let year = vm.movie.releaseYear {
                                Text("\(year) · DIRECTED BY")
                                    .font(.caption.weight(.medium))
                                    .tracking(1.2)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            if let director = vm.movie.director, !director.isEmpty {
                                Text(director)
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: "#C5D2DE"))
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        if let runtime = vm.movie.runtimeMinutes {
                            Label("\(runtime) mins", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        if vm.isWatched {
                            Label("Watched", systemImage: "eye.fill")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.green)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PosterView(url: vm.movie.posterUrl, width: 112, height: 168)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let urlString = vm.movie.backdropUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    backdropFallback
                }
            }
        } else {
            backdropFallback
        }
    }

    private var backdropFallback: some View {
        ZStack {
            AppTheme.secondaryBackground
            Image(systemName: "film.fill")
                .font(.system(size: 62))
                .foregroundStyle(AppTheme.cardBackground)
        }
    }

    // MARK: - Overview / ratings

    @ViewBuilder
    private var overviewSection: some View {
        if let overview = vm.movie.overview, !overview.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(overview)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(4)
                    .lineLimit(showFullOverview ? nil : 4)

                if overview.count > 180 {
                    Button(showFullOverview ? "Less" : "More") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showFullOverview.toggle()
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.blue)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
    }

    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("RATINGS")

            HStack(alignment: .bottom, spacing: 10) {
                Text("★")
                    .font(.caption)
                    .foregroundStyle(AppTheme.green)

                RatingHistogram(buckets: vm.ratingsDistribution)
                    .frame(height: 74)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(vm.movie.averageRating.map { String(format: "%.1f", $0) } ?? "—")
                        .font(.title3)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("★★★★★")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.green)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .overlay(alignment: .top) {
            Divider().overlay(Color.white.opacity(0.08))
        }
    }

    private var userActivityCard: some View {
        Button {
            showLogSheet = true
        } label: {
            HStack(spacing: 10) {
                userAvatar

                VStack(alignment: .leading, spacing: 3) {
                    Text(userActivityTitle)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let rating = vm.userReview?.rating ?? vm.userRating, rating > 0 {
                        MovieCompactStars(rating: rating, size: 13)
                    }
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 62)
            .background(Color(hex: "#526779"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }

    private var userActivityTitle: String {
        if vm.userReview != nil { return "You've reviewed this film" }
        if vm.isWatched { return "You've watched this film" }
        return "Log or review this film"
    }

    private var userAvatar: some View {
        AsyncImage(url: APIConfig.mediaURL(for: authViewModel.currentUser?.avatarUrl)) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default:
                ZStack {
                    Color.black.opacity(0.25)
                    Image(systemName: "person.fill")
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(Circle())
    }

    // MARK: - Social stats

    @ViewBuilder
    private var watchedBySection: some View {
        if !vm.watchedBy.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("WATCHED BY")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 13) {
                        ForEach(vm.watchedBy) { member in
                            NavigationLink {
                                ProfileView(
                                    userId: member.userId,
                                    isOwnProfile: authViewModel.currentUser?.id == member.userId
                                )
                            } label: {
                                VStack(spacing: 5) {
                                    memberAvatar(member)
                                    if let rating = member.rating {
                                        MovieCompactStars(rating: rating, size: 8)
                                    } else {
                                        Text(" ").font(.caption2)
                                    }
                                }
                                .frame(width: 52)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .overlay(alignment: .top) {
                Divider().overlay(Color.white.opacity(0.08))
            }
        }
    }

    private func memberAvatar(_ member: MovieWatchedByUser) -> some View {
        AsyncImage(url: APIConfig.mediaURL(for: member.avatarUrl)) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default:
                ZStack {
                    AppTheme.cardBackground
                    Image(systemName: "person.fill")
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }

    private var statsCards: some View {
        HStack(spacing: 12) {
            NavigationLink {
                MovieMembersView(movie: vm.movie)
            } label: {
                MovieStatCard(
                    icon: "eye.fill",
                    title: "Members",
                    value: abbreviated(vm.stats.membersCount),
                    tint: AppTheme.green
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                MovieReviewsView(movie: vm.movie)
            } label: {
                MovieStatCard(
                    icon: "list.bullet.rectangle.fill",
                    title: "Reviews",
                    value: abbreviated(vm.stats.reviewCount),
                    tint: Color(hex: "#8195A7")
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                MovieContainingListsView(movie: vm.movie)
            } label: {
                MovieStatCard(
                    icon: "rectangle.stack.fill",
                    title: "Lists",
                    value: abbreviated(vm.stats.listCount),
                    tint: AppTheme.blue
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Divider().overlay(Color.white.opacity(0.08))
        }
    }

    // MARK: - Info tabs

    private var infoSection: some View {
        VStack(spacing: 0) {
            MovieInfoTabBar(selected: $infoTab)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)

            infoContent
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
        }
        .overlay(alignment: .top) {
            Divider().overlay(Color.white.opacity(0.08))
        }
    }

    @ViewBuilder
    private var infoContent: some View {
        switch infoTab {
        case .cast:
            castContent
        case .crew:
            crewContent
        case .details:
            detailsContent
        case .genres:
            genresContent
        case .releases:
            releasesContent
        }
    }

    @ViewBuilder
    private var castContent: some View {
        if vm.movie.cast.isEmpty {
            infoEmpty("No cast data available.")
        } else {
            VStack(spacing: 0) {
                ForEach(Array(displayedCast.enumerated()), id: \.offset) { _, actor in
                    PersonInfoRow(name: actor, subtitle: nil)
                }

                if vm.movie.cast.count > 10 {
                    Button(showAllCast ? "Show less" : "Show \(vm.movie.cast.count - 10) more") {
                        showAllCast.toggle()
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var displayedCast: [String] {
        showAllCast ? vm.movie.cast : Array(vm.movie.cast.prefix(10))
    }

    @ViewBuilder
    private var crewContent: some View {
        if let director = vm.movie.director, !director.isEmpty {
            PersonInfoRow(name: director, subtitle: "Director")
        } else {
            infoEmpty("No crew data available.")
        }
    }

    private var detailsContent: some View {
        VStack(spacing: 0) {
            if let year = vm.movie.releaseYear {
                DetailInfoRow(label: "Year", value: String(year))
            }
            if let runtime = vm.movie.runtimeMinutes {
                DetailInfoRow(label: "Runtime", value: "\(runtime) mins")
            }
            if let director = vm.movie.director, !director.isEmpty {
                DetailInfoRow(label: "Director", value: director)
            }
            if !vm.movie.keywords.isEmpty {
                DetailInfoRow(label: "Keywords", value: vm.movie.keywords.prefix(8).joined(separator: ", "))
            }
        }
    }

    @ViewBuilder
    private var genresContent: some View {
        if vm.movie.genres.isEmpty {
            infoEmpty("No genre data available.")
        } else {
            FlowingChips(values: vm.movie.genres)
        }
    }

    private var releasesContent: some View {
        VStack(spacing: 0) {
            if let year = vm.movie.releaseYear {
                DetailInfoRow(label: "Release year", value: String(year))
            } else {
                infoEmpty("No release data available.")
            }
        }
    }

    private func infoEmpty(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
    }

    // MARK: - Reviews / related

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            MovieReviewPreviewTabs(selected: vm.selectedReviewTab) { tab in
                Task { await vm.selectReviewTab(tab) }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 18)

            sectionLabel(vm.selectedReviewTab == .popular ? "POPULAR REVIEWS" : "REVIEWS")
                .padding(.horizontal, 18)
                .padding(.bottom, 10)

            if vm.isLoadingReviews {
                ProgressView()
                    .tint(AppTheme.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
            } else if vm.reviews.isEmpty {
                Text("No reviews in this view yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
            } else {
                ForEach(vm.reviews) { review in
                    NavigationLink {
                        ReviewDetailView(movie: vm.movie, review: review)
                    } label: {
                        MovieReviewRow(review: review)
                            .padding(.horizontal, 18)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .overlay(Color.white.opacity(0.08))
                        .padding(.leading, 18)
                }
            }

            NavigationLink {
                MovieReviewsView(movie: vm.movie)
            } label: {
                HStack {
                    Text("All reviews")
                        .font(.body)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color(hex: "#496071"))
                }
                .padding(.horizontal, 18)
                .frame(height: 54)
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: .top) {
            Divider().overlay(Color.white.opacity(0.08))
        }
    }

    @ViewBuilder
    private var filmRows: some View {
        if !vm.similarMovies.isEmpty {
            MoviePosterStrip(
                title: "RELATED FILMS",
                films: Array(vm.similarMovies.prefix(3))
            )

            if vm.similarMovies.count > 3 {
                MoviePosterStrip(
                    title: "SIMILAR FILMS",
                    films: Array(vm.similarMovies.dropFirst(3))
                )
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .tracking(1.3)
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func abbreviated(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fm", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fk", Double(value) / 1_000)
        }
        return String(value)
    }
}

// MARK: - Members who watched this movie

struct MovieMembersView: View {
    let movie: Movie

    @State private var members: [MovieMember] = []
    @State private var total = 0
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if isLoading && members.isEmpty {
                ProgressView().tint(AppTheme.green)
            } else if let errorMessage, members.isEmpty {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn’t load members",
                    subtitle: errorMessage
                )
                .padding()
            } else if members.isEmpty {
                EmptyStateView(
                    icon: "eye",
                    title: "No members yet",
                    subtitle: "Nobody has marked this film as watched yet."
                )
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        HStack {
                            Text("\(total) MEMBER\(total == 1 ? "" : "S") WATCHED THIS FILM")
                                .font(.caption.weight(.medium))
                                .tracking(1.2)
                                .foregroundStyle(AppTheme.secondaryText)

                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)

                        Divider().overlay(Color.white.opacity(0.08))

                        ForEach(members) { member in
                            NavigationLink {
                                ProfileView(
                                    userId: member.userId,
                                    isOwnProfile: member.isCurrentUser
                                )
                            } label: {
                                memberRow(member)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 78)
                        }
                    }
                }
            }
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .task { await load() }
    }

    private func memberRow(_ member: MovieMember) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: APIConfig.mediaURL(for: member.avatarUrl)) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    ZStack {
                        AppTheme.cardBackground
                        Image(systemName: "person.fill")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(member.username)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if member.isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.7)
                            .foregroundStyle(AppTheme.background)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    } else if member.isFollowing {
                        Text("FOLLOWING")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(Color(hex: "#9AB1C5"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#26323B"))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    } else {
                        Text("NOT FOLLOWING")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                if let bio = member.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let rating = member.rating, rating > 0 {
                MovieCompactStars(rating: rating, size: 10)
                    .fixedSize()
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.2))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await MovieService.shared.members(movieId: movie.id)
            members = response.members
            total = response.total
        } catch {
            members = []
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Public lists containing this movie

struct MovieContainingListsView: View {
    let movie: Movie

    @State private var lists: [MovieContainingList] = []
    @State private var total = 0
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if isLoading && lists.isEmpty {
                ProgressView().tint(AppTheme.green)
            } else if let errorMessage, lists.isEmpty {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn’t load lists",
                    subtitle: errorMessage
                )
                .padding()
            } else if lists.isEmpty {
                EmptyStateView(
                    icon: "rectangle.stack",
                    title: "No lists yet",
                    subtitle: "This film hasn’t been added to a public list yet."
                )
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        HStack {
                            Text("\(total) LIST\(total == 1 ? "" : "S") CONTAIN THIS FILM")
                                .font(.caption.weight(.medium))
                                .tracking(1.2)
                                .foregroundStyle(AppTheme.secondaryText)

                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)

                        Divider().overlay(Color.white.opacity(0.08))

                        ForEach(lists) { list in
                            NavigationLink {
                                MovieListDetailView(
                                    listId: list.id,
                                    title: list.name
                                )
                            } label: {
                                listRow(list)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 18)
                        }
                    }
                }
            }
        }
        .navigationTitle("Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .task { await load() }
    }

    private func listRow(_ list: MovieContainingList) -> some View {
        HStack(alignment: .top, spacing: 14) {
            MovieListPosterStack(urls: list.posterUrls)

            VStack(alignment: .leading, spacing: 6) {
                Text(list.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    AsyncImage(url: APIConfig.mediaURL(for: list.avatarUrl)) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .frame(width: 19, height: 19)
                    .clipShape(Circle())

                    Text(list.username)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "#A9BBCB"))

                    Text("·")
                        .foregroundStyle(AppTheme.secondaryText)

                    Text("\(list.movieCount) film\(list.movieCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                if let description = list.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                        .lineSpacing(2)
                }
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.2))
                .padding(.top, 28)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await MovieService.shared.containingLists(movieId: movie.id)
            lists = response.lists
            total = response.total
        } catch {
            lists = []
            errorMessage = error.localizedDescription
        }
    }
}

private struct MovieListPosterStack: View {
    let urls: [String]

    var body: some View {
        ZStack(alignment: .leading) {
            if urls.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.cardBackground)
                    .frame(width: 74, height: 108)
                    .overlay {
                        Image(systemName: "rectangle.stack.fill")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
            } else {
                ForEach(Array(urls.prefix(3).enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: APIConfig.mediaURL(for: url)) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            AppTheme.cardBackground
                        }
                    }
                    .frame(width: 58, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }
                    .offset(x: CGFloat(index) * 8)
                }
            }
        }
        .frame(width: 78, height: 108, alignment: .leading)
    }
}

// MARK: - Reviews page

struct MovieReviewsView: View {
    let movie: Movie

    @State private var selectedFilter: MovieReviewsFilter = .everyone
    @State private var reviews: [MovieReview] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                reviewFilterBar
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                Divider().overlay(Color.white.opacity(0.08))

                if isLoading && reviews.isEmpty {
                    Spacer()
                    ProgressView().tint(AppTheme.green)
                    Spacer()
                } else if let errorMessage, reviews.isEmpty {
                    Spacer()
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else if reviews.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "text.bubble",
                        title: "No reviews",
                        subtitle: "There are no reviews in this filter yet."
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(reviews) { review in
                                NavigationLink {
                                    ReviewDetailView(movie: movie, review: review)
                                } label: {
                                    MovieReviewRow(review: review)
                                        .padding(.horizontal, 18)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .overlay(Color.white.opacity(0.08))
                                    .padding(.leading, 18)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reviews of \(movie.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .task { await load() }
    }

    private var reviewFilterBar: some View {
        HStack(spacing: 2) {
            ForEach(MovieReviewsFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                    Task { await load() }
                } label: {
                    Text(filter.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedFilter == filter ? .white : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(selectedFilter == filter ? Color(hex: "#71869A") : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color(hex: "#20262C"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            reviews = try await MovieService.shared.reviews(
                movieId: movie.id,
                filter: selectedFilter,
                sortBy: selectedFilter == .everyone ? "mostLiked" : "newest",
                limit: 100
            )
        } catch {
            reviews = []
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Review detail

struct ReviewDetailView: View {
    let movie: Movie
    let review: MovieReview

    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var vm: ReviewDetailViewModel
    @State private var commentText = ""
    @State private var revealSpoiler = false
    @FocusState private var commentFieldFocused: Bool

    init(movie: Movie, review: MovieReview) {
        self.movie = movie
        self.review = review
        _vm = StateObject(wrappedValue: ReviewDetailViewModel(review: review))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    reviewHeader
                    reviewBody
                    likeSection
                    tagsSection
                    commentsSection
                    navigationButtons
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .task { await vm.loadComments() }
        .alert("Review", isPresented: Binding(
            get: { vm.message != nil },
            set: { if !$0 { vm.message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.message ?? "")
        }
    }

    private var reviewHeader: some View {
        VStack(spacing: 0) {
            AsyncImage(url: APIConfig.mediaURL(for: movie.backdropUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    ZStack {
                        Color(hex: "#20272D")
                        Image(systemName: "film")
                            .font(.system(size: 42))
                            .foregroundStyle(Color.white.opacity(0.18))
                    }
                }
            }
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, AppTheme.background.opacity(0.9), AppTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 125)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    NavigationLink {
                        ProfileView(
                            userId: review.userId,
                            isOwnProfile: authViewModel.currentUser?.id == review.userId
                        )
                    } label: {
                        HStack(spacing: 9) {
                            reviewerAvatar

                            Text(review.username)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)

                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text(movie.title)
                            .font(.system(size: 25, weight: .bold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        if let year = movie.releaseYear {
                            Text(String(year))
                                .font(.title3)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    HStack(spacing: 8) {
                        if let rating = review.rating {
                            MovieCompactStars(rating: rating, size: 17)
                        }

                        if review.likedMovie {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(AppTheme.orange)
                        }

                        if review.isRewatch {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(Color(hex: "#60778A"))
                        }
                    }

                    if let date = formattedDate(review.createdAt) {
                        Text("Watched \(date)")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "#657B8E"))
                    }
                }

                Spacer(minLength: 4)

                PosterView(url: movie.posterUrl, width: 105, height: 157)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 18)
            .padding(.top, -24)
            .padding(.bottom, 18)
        }
    }

    private var reviewerAvatar: some View {
        AsyncImage(url: APIConfig.mediaURL(for: review.avatarUrl)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    AppTheme.cardBackground
                    Image(systemName: "person.fill")
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .frame(width: 38, height: 38)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    private var reviewBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            if review.isSpoiler && !revealSpoiler {
                Button {
                    revealSpoiler = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.slash")
                        Text("This review contains spoilers — tap to reveal")
                    }
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            } else {
                Text(review.content)
                    .font(.system(size: 19))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 22)
    }

    private var likeSection: some View {
        HStack(spacing: 15) {
            Button {
                Task { await vm.toggleLike() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: vm.likedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 25, weight: .regular))
                        .foregroundStyle(vm.likedByMe ? AppTheme.orange : AppTheme.secondaryText)

                    Text(vm.likedByMe ? "LIKED" : "LIKE?")
                        .font(.subheadline.weight(.medium))
                        .tracking(1.0)
                        .foregroundStyle(vm.likedByMe ? AppTheme.orange : AppTheme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            Text("\(vm.likeCount) \(vm.likeCount == 1 ? "like" : "likes")")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "#52677A"))

            Spacer()

            if vm.commentCount > 0 {
                Label("\(vm.commentCount)", systemImage: "bubble.left")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#52677A"))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Divider().overlay(Color.white.opacity(0.08))
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if !review.tags.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("TAGS")
                    .font(.caption.weight(.medium))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.secondaryText)

                FlowingChips(values: review.tags)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .overlay(alignment: .top) {
                Divider().overlay(Color.white.opacity(0.08))
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("COMMENTS")
                    .font(.caption.weight(.medium))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Text(String(vm.commentCount))
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#52677A"))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)

            if vm.isLoadingComments && vm.comments.isEmpty {
                ProgressView()
                    .tint(AppTheme.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
            } else if vm.comments.isEmpty {
                Text("No replies yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
            } else {
                ForEach(vm.comments) { comment in
                    ReviewCommentRow(comment: comment)
                    Divider()
                        .overlay(Color.white.opacity(0.07))
                        .padding(.leading, 64)
                }
            }

            if review.commentsEnabled {
                commentComposer
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
            } else {
                Text("Replies are disabled for this review.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
            }
        }
        .overlay(alignment: .top) {
            Divider().overlay(Color.white.opacity(0.08))
        }
    }

    private var commentComposer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            AsyncImage(url: APIConfig.mediaURL(for: authViewModel.currentUser?.avatarUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        AppTheme.cardBackground
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())

            TextField("Write a reply…", text: $commentText, axis: .vertical)
                .lineLimit(1...4)
                .focused($commentFieldFocused)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(hex: "#242D34"))
                .clipShape(RoundedRectangle(cornerRadius: 9))

            Button {
                submitComment()
            } label: {
                if vm.isSavingComment {
                    ProgressView()
                        .tint(AppTheme.green)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(canSendComment ? AppTheme.green : Color(hex: "#51616D"))
                }
            }
            .disabled(!canSendComment || vm.isSavingComment)
            .buttonStyle(.plain)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if review.commentsEnabled {
                Button {
                    commentFieldFocused = true
                } label: {
                    ReviewPillButton(title: "Reply", icon: nil)
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                ProfileView(
                    userId: review.userId,
                    isOwnProfile: authViewModel.currentUser?.id == review.userId
                )
            } label: {
                ReviewPillButton(title: "Activity", icon: "chevron.right")
            }
            .buttonStyle(.plain)

            NavigationLink {
                MovieDetailView(movie: movie)
            } label: {
                ReviewPillButton(title: "Film", icon: "chevron.right")
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
    }

    private var canSendComment: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitComment() {
        guard canSendComment else { return }
        let text = commentText

        Task {
            if await vm.postComment(text) {
                commentText = ""
                commentFieldFocused = false
            }
        }
    }

    private func formattedDate(_ value: String?) -> String? {
        guard let value else { return nil }
        guard let date = ReviewDateFormatter.parse(value) else { return nil }
        return ReviewDateFormatter.display.string(from: date)
    }
}

private struct ReviewCommentRow: View {
    let comment: ReviewComment

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            AsyncImage(url: APIConfig.mediaURL(for: comment.avatarUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        AppTheme.cardBackground
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(comment.username)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    if let date = ReviewDateFormatter.parse(comment.createdAt) {
                        Text(ReviewDateFormatter.short.string(from: date))
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#52677A"))
                    }
                }

                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }
}

private struct ReviewPillButton: View {
    let title: String
    let icon: String?

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color(hex: "#D2DFEA"))
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(Color(hex: "#344B5D"))
        .clipShape(Capsule())
    }
}

private enum ReviewDateFormatter {
    static let isoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let isoBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        return isoFractional.date(from: value) ?? isoBasic.date(from: value)
    }
}

// MARK: - Small components

private enum MovieInfoTab: String, CaseIterable {
    case cast = "Cast"
    case crew = "Crew"
    case details = "Details"
    case genres = "Genres"
    case releases = "Releases"
}

private struct MovieInfoTabBar: View {
    @Binding var selected: MovieInfoTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MovieInfoTab.allCases, id: \.self) { tab in
                Button {
                    selected = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selected == tab ? .white : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(selected == tab ? Color(hex: "#71869A") : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct MovieReviewPreviewTabs: View {
    let selected: MovieReviewPreviewTab
    let onSelect: (MovieReviewPreviewTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MovieReviewPreviewTab.allCases, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selected == tab ? .white : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(selected == tab ? Color(hex: "#71869A") : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct RatingHistogram: View {
    let buckets: [MovieRatingBucket]

    private var maxCount: Int {
        max(buckets.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(buckets) { bucket in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(hex: "#53697B"))
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 2,
                        maxHeight: max(2, CGFloat(bucket.count) / CGFloat(maxCount) * 72)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
    }
}

private struct MovieStatCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)

            Spacer(minLength: 6)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, minHeight: 102, alignment: .leading)
        .padding(12)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PersonInfoRow: View {
    let name: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.cardBackground)
                Text(initials)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#526A7D"))
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
        }
    }

    private var initials: String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

private struct DetailInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Text(label.uppercased())
                .font(.caption.weight(.medium))
                .tracking(0.8)
                .foregroundStyle(Color(hex: "#60788A"))
                .frame(width: 88, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.white.opacity(0.07))
        }
    }
}

private struct FlowingChips: View {
    let values: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunked(values, size: 3), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { value in
                        Text(value)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(AppTheme.cardBackground)
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chunked(_ values: [String], size: Int) -> [[String]] {
        stride(from: 0, to: values.count, by: size).map { index in
            Array(values[index..<min(index + size, values.count)])
        }
    }
}

private struct MovieReviewRow: View {
    let review: MovieReview

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                if let rating = review.rating {
                    MovieCompactStars(rating: rating, size: 15)
                }

                if review.likedMovie {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.orange)
                }

                if review.isRewatch {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#536B7D"))
                }

                Spacer()

                if review.commentCount > 0 {
                    Label(String(review.commentCount), systemImage: "bubble.left")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#526A7D"))
                }

                if review.likeCount > 0 {
                    Label(String(review.likeCount), systemImage: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#526A7D"))
                }

                Text(review.username)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#526A7D"))

                AsyncImage(url: APIConfig.mediaURL(for: review.avatarUrl)) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default:
                        ZStack {
                            AppTheme.cardBackground
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
                .frame(width: 30, height: 30)
                .clipShape(Circle())
            }

            if review.isSpoiler {
                Label("This review contains spoilers — open to reveal", systemImage: "eye.slash")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                Text(review.content)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 16)
    }
}

private struct MovieCompactStars: View {
    let rating: Double
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: symbol(for: star))
                    .font(.system(size: size))
                    .foregroundStyle(AppTheme.green)
            }
        }
    }

    private func symbol(for star: Int) -> String {
        let full = Double(star)
        let half = full - 0.5
        if rating >= full { return "star.fill" }
        if rating >= half { return "star.leadinghalf.filled" }
        return "star"
    }
}

private struct MoviePosterStrip: View {
    let title: String
    let films: [SimilarMovie]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                    .tracking(1.3)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(hex: "#496071"))
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(films) { item in
                        NavigationLink {
                            MovieDetailView(movie: item.asMovie)
                        } label: {
                            PosterView(url: item.posterUrl, width: 104, height: 156)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Divider().overlay(Color.white.opacity(0.08))
        }
    }
}
