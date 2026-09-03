import SwiftUI

private enum HomeTab: Hashable {
    case films
    case reviews
    case lists
    case journal
}

struct HomeView: View {
    @State private var selectedTab: HomeTab = .films
    @State private var home: HomeResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    homeHeader
                    homeTabs

                    Divider()
                        .overlay(Color.white.opacity(0.08))

                    content
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await load(force: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: .diaryDidChange)) { _ in
                Task { await load(force: true) }
            }
        }
    }

    private var homeHeader: some View {
        HStack {
            Spacer()

            Text("Letterboxd")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Spacer()
        }
        .overlay(alignment: .trailing) {
            
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(Color.black)
    }

    private var homeTabs: some View {
        PillTabBar(
            tabs: [
                (.films, "Films"),
                (.reviews, "Reviews"),
                (.lists, "Lists"),
                (.journal, "Journal"),
            ],
            selection: $selectedTab
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 7)
        .background(Color.black)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && home == nil {
            Spacer()
            ProgressView().tint(AppTheme.green)
            Spacer()
        } else if let errorMessage, home == nil {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.secondaryText)

                Text("Couldn’t load Home")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)

                Button("Try again") {
                    Task { await load(force: true) }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.green)
            }
            .padding(28)
            Spacer()
        } else if let home {
            switch selectedTab {
            case .films:
                filmsTab(home)
            case .reviews:
                reviewsTab(home)
            case .lists:
                listsTab(home)
            case .journal:
                journalTab(home)
            }
        }
    }

    private func filmsTab(_ home: HomeResponse) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                NavigationLink {
                    HomeProInfoView()
                } label: {
                    proBanner
                }
                .buttonStyle(.plain)

                HomePosterSection(
                    title: "Popular this week",
                    movies: home.popularThisWeek,
                    destinationTitle: "Popular this week"
                )

                HomeFriendsSection(
                    title: "New from friends",
                    activities: home.newFromFriends
                )

                HomePosterSection(
                    title: "Popular with friends",
                    movies: home.popularWithFriends,
                    destinationTitle: "Popular with friends"
                )
            }
            .padding(.bottom, 22)
        }
        .refreshable {
            await load(force: true)
        }
    }

    private func reviewsTab(_ home: HomeResponse) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HomePageHeading(
                    title: "Popular reviews",
                    subtitle: "What the community is talking about"
                )

                if home.popularReviews.isEmpty {
                    EmptyStateView(
                        icon: "text.bubble",
                        title: "No reviews yet",
                        subtitle: "Popular reviews will appear here."
                    )
                    .padding(.vertical, 50)
                } else {
                    ForEach(home.popularReviews) { review in
                        NavigationLink {
                            MovieDetailView(movie: review.asMovie)
                        } label: {
                            HomeReviewRow(review: review)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.leading, 18)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            await load(force: true)
        }
    }

    private func listsTab(_ home: HomeResponse) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HomePageHeading(
                    title: "Popular lists",
                    subtitle: "Lists from the Letterboxd community"
                )

                if home.popularLists.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.stack",
                        title: "No lists yet",
                        subtitle: "Public lists will appear here."
                    )
                    .padding(.vertical, 50)
                } else {
                    ForEach(home.popularLists) { list in
                        NavigationLink {
                            MovieListDetailView(
                                listId: list.id,
                                title: list.name
                            )
                        } label: {
                            HomeListRow(list: list)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.leading, 18)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            await load(force: true)
        }
    }

    private func journalTab(_ home: HomeResponse) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                HomePageHeading(
                    title: "Journal",
                    subtitle: "A local community digest from your app data"
                )

                if let movie = home.popularThisWeek.first {
                    NavigationLink {
                        MovieDetailView(movie: movie.asMovie)
                    } label: {
                        HomeJournalCard(
                            eyebrow: "THIS WEEK IN FILM",
                            title: movie.title,
                            summary: "One of the films members are watching most right now.",
                            posterURL: movie.posterUrl
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let review = home.popularReviews.first {
                    NavigationLink {
                        MovieDetailView(movie: review.asMovie)
                    } label: {
                        HomeJournalCard(
                            eyebrow: "COMMUNITY VOICES",
                            title: "A review of \(review.title)",
                            summary: review.isSpoiler
                                ? "A popular community review contains spoilers. Open the film to read it safely."
                                : review.content,
                            posterURL: review.posterUrl
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let list = home.popularLists.first {
                    NavigationLink {
                        MovieListDetailView(
                            listId: list.id,
                            title: list.name
                        )
                    } label: {
                        HomeJournalCard(
                            eyebrow: "LISTS WORTH EXPLORING",
                            title: list.name,
                            summary: list.description?.isEmpty == false
                                ? list.description!
                                : "A popular public list by \(list.username).",
                            posterURL: list.posterUrls.first
                        )
                    }
                    .buttonStyle(.plain)
                }

                Text("Journal brings together interviews, festival coverage, essays, community stories and platform features from across the world of film.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
            }
            .padding(.bottom, 28)
        }
        .refreshable {
            await load(force: true)
        }
    }

    private var proBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("PRO")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(AppTheme.orange)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text("Remove ads, add profile stats, activity and service filters, favorite streaming services and more by upgrading to Pro.")
                .font(.caption)
                .foregroundStyle(Color(hex: "#CBD7E1"))
                .lineSpacing(2)

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.3))
                .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(Color(hex: "#2C3944"))
    }

    @MainActor
    private func load(force: Bool) async {
        if home != nil && !force {
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            home = try await HomeService.shared.fetchHome()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Films tab sections

private struct HomePosterSection: View {
    let title: String
    let movies: [HomeMovieItem]
    let destinationTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                HomeMoviesGridView(
                    title: destinationTitle,
                    movies: movies
                )
            } label: {
                HomeSectionHeader(title: title)
            }
            .buttonStyle(.plain)

            if movies.isEmpty {
                Text("Nothing to show yet.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(movies) { movie in
                            NavigationLink {
                                MovieDetailView(movie: movie.asMovie)
                            } label: {
                                PosterView(
                                    url: movie.posterUrl,
                                    width: 84,
                                    height: 126
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
        .padding(.top, 13)
        .padding(.bottom, 10)
    }
}

private struct HomeFriendsSection: View {
    let title: String
    let activities: [HomeFriendActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                HomeFriendActivityView(
                    title: title,
                    activities: activities
                )
            } label: {
                HomeSectionHeader(title: title)
            }
            .buttonStyle(.plain)

            if activities.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No recent activity from friends")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Follow members to see what they’re rating and reviewing.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 9) {
                        ForEach(activities) { activity in
                            NavigationLink {
                                MovieDetailView(movie: activity.asMovie)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    PosterView(
                                        url: activity.posterUrl,
                                        width: 84,
                                        height: 126
                                    )

                                    HStack(spacing: 4) {
                                        HomeAvatar(
                                            url: activity.avatarUrl,
                                            size: 18
                                        )

                                        Text(activity.username)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(AppTheme.secondaryText)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 84, alignment: .leading)

                                    if let rating = activity.rating, rating > 0 {
                                        HomeStars(rating: rating, size: 8)
                                    } else {
                                        Image(systemName: activity.type == "review" ? "text.bubble.fill" : "film.fill")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
        .padding(.top, 9)
        .padding(.bottom, 10)
    }
}

private struct HomeSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.35))
        }
        .padding(.horizontal, 18)
    }
}

private struct HomePageHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

// MARK: - Reviews tab

private struct HomeReviewRow: View {
    let review: HomeReviewItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PosterView(
                url: review.posterUrl,
                width: 58,
                height: 87
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    HomeAvatar(
                        url: review.avatarUrl,
                        size: 22
                    )

                    Text(review.username)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "#B9C8D4"))
                }

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(review.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let year = review.releaseYear {
                        Text(String(year))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                if let rating = review.rating, rating > 0 {
                    HomeStars(rating: rating, size: 10)
                }

                if review.isSpoiler {
                    Label("Contains spoilers", systemImage: "eye.slash")
                        .font(.caption)
                        .foregroundStyle(AppTheme.orange)
                } else {
                    Text(review.content)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(3)
                        .lineSpacing(2)
                }

                HStack(spacing: 13) {
                    Label("\(review.likeCount)", systemImage: "heart.fill")
                    Label("\(review.commentCount)", systemImage: "bubble.left.fill")
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer(minLength: 5)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.25))
                .padding(.top, 32)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Lists tab

private struct HomeListRow: View {
    let list: HomeListItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            HomeListPosterStack(urls: list.posterUrls)

            VStack(alignment: .leading, spacing: 6) {
                Text(list.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    HomeAvatar(
                        url: list.avatarUrl,
                        size: 19
                    )

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

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.25))
                .padding(.top, 28)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }
}

private struct HomeListPosterStack: View {
    let urls: [String]

    var body: some View {
        ZStack(alignment: .leading) {
            if urls.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.cardBackground)
                    .frame(width: 75, height: 108)
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

// MARK: - Journal

private struct HomeJournalCard: View {
    let eyebrow: String
    let title: String
    let summary: String
    let posterURL: String?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            PosterView(
                url: posterURL,
                width: 82,
                height: 122
            )

            VStack(alignment: .leading, spacing: 7) {
                Text(eyebrow)
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.blue)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(summary)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(4)
                    .lineSpacing(2)

                HStack(spacing: 5) {
                    Text("Read more")
                    Image(systemName: "chevron.right")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "#B8C8D5"))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .padding(.horizontal, 18)
    }
}

// MARK: - Supporting pages

private struct HomeMoviesGridView: View {
    let title: String
    let movies: [HomeMovieItem]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 95), spacing: 10)
                    ],
                    spacing: 14
                ) {
                    ForEach(movies) { movie in
                        NavigationLink {
                            MovieDetailView(movie: movie.asMovie)
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
    }
}

private struct HomeFriendActivityView: View {
    let title: String
    let activities: [HomeFriendActivity]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if activities.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No friend activity",
                    subtitle: "Follow members to see their recent films here."
                )
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(activities) { activity in
                            NavigationLink {
                                MovieDetailView(movie: activity.asMovie)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    PosterView(
                                        url: activity.posterUrl,
                                        width: 54,
                                        height: 81
                                    )

                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            HomeAvatar(
                                                url: activity.avatarUrl,
                                                size: 22
                                            )

                                            Text(activity.username)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color(hex: "#B8C8D5"))
                                        }

                                        Text(activity.title)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(.white)

                                        if let rating = activity.rating, rating > 0 {
                                            HomeStars(rating: rating, size: 10)
                                        }

                                        if activity.type == "review",
                                           let reviewText = activity.reviewText,
                                           !reviewText.isEmpty {
                                            Text(activity.isSpoiler == true ? "Contains spoilers" : reviewText)
                                                .font(.caption)
                                                .foregroundStyle(activity.isSpoiler == true ? AppTheme.orange : AppTheme.secondaryText)
                                                .lineLimit(2)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.25))
                                        .padding(.top, 30)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
    }
}

private struct HomeProInfoView: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 9) {
                            Text("PRO")
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(AppTheme.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text("Upgrade your Letterboxd")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                        }

                        Text("Support Letterboxd and unlock more ways to explore your film life.")
                            .font(.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineSpacing(3)
                    }

                    HomeMembershipTierCard(
                        badge: "FREE",
                        title: "Free",
                        accent: AppTheme.secondaryText,
                        features: [
                            "Unlimited films, diary entries, ratings, reviews and lists",
                            "Watchlist, activity and community features"
                        ]
                    )

                    HomeMembershipTierCard(
                        badge: "PRO",
                        title: "Pro",
                        accent: AppTheme.orange,
                        features: [
                            "No third-party ads",
                            "Personalized annual and all-time stats",
                            "Choose favorite streaming services and filter by availability",
                            "Watchlist availability notifications",
                            "Filter your activity feed by activity type",
                            "Pin content to your profile, duplicate lists and manage tags"
                        ]
                    )

                    HomeMembershipTierCard(
                        badge: "PATRON",
                        title: "Patron",
                        accent: AppTheme.blue,
                        features: [
                            "Everything included with Pro",
                            "Choose preferred posters and backdrops",
                            "Choose preferred cast and crew images",
                            "Additional profile customization",
                            "Patron directory listing and early access to selected features"
                        ]
                    )

                    Text("Subscriptions renew annually unless cancelled before renewal.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 2)
                }
                .padding(20)
            }
        }
        .navigationTitle("Subscriptions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
    }
}

private struct HomeMembershipTierCard: View {
    let badge: String
    let title: String
    let accent: Color
    let features: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 9) {
                Text(badge)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(.top, 2)

                    Text(feature)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#C5D2DD"))
                        .lineSpacing(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }
}

// MARK: - Shared Home visual helpers

private struct HomeAvatar: View {
    let url: String?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: APIConfig.mediaURL(for: url)) { phase in
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
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private struct HomeStars: View {
    let rating: Double
    let size: CGFloat

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: symbol(for: star))
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(AppTheme.green)
            }
        }
    }

    private func symbol(for star: Int) -> String {
        let value = Double(star)

        if rating >= value {
            return "star.fill"
        }

        if rating >= value - 0.5 {
            return "star.leadinghalf.filled"
        }

        return "star"
    }
}

// MARK: - Home API models

private struct HomeResponse: Decodable {
    let popularThisWeek: [HomeMovieItem]
    let newFromFriends: [HomeFriendActivity]
    let popularWithFriends: [HomeMovieItem]
    let popularReviews: [HomeReviewItem]
    let popularLists: [HomeListItem]

    enum CodingKeys: String, CodingKey {
        case popularThisWeek
        case newFromFriends
        case popularWithFriends
        case popularReviews
        case popularLists
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        popularThisWeek = (try? c.decode([HomeMovieItem].self, forKey: .popularThisWeek)) ?? []
        newFromFriends = (try? c.decode([HomeFriendActivity].self, forKey: .newFromFriends)) ?? []
        popularWithFriends = (try? c.decode([HomeMovieItem].self, forKey: .popularWithFriends)) ?? []
        popularReviews = (try? c.decode([HomeReviewItem].self, forKey: .popularReviews)) ?? []
        popularLists = (try? c.decode([HomeListItem].self, forKey: .popularLists)) ?? []
    }
}

private struct HomeMovieItem: Decodable, Identifiable {
    let id: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?
    let averageRating: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case releaseYear
        case posterUrl
        case averageRating
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.homeFlexibleInt(.id) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        releaseYear = c.homeFlexibleInt(.releaseYear)
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        averageRating = c.homeFlexibleDouble(.averageRating)
    }

    var asMovie: Movie {
        Movie(
            id: id,
            title: title,
            releaseYear: releaseYear,
            posterUrl: posterUrl,
            averageRating: averageRating
        )
    }
}

private struct HomeFriendActivity: Decodable, Identifiable {
    let type: String
    let occurredAt: String?
    let userId: Int
    let username: String
    let avatarUrl: String?
    let movieId: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?
    let rating: Double?
    let reviewText: String?
    let isSpoiler: Bool?

    var id: String {
        "\(userId)-\(movieId)-\(occurredAt ?? type)"
    }

    enum CodingKeys: String, CodingKey {
        case type
        case occurredAt
        case userId
        case username
        case avatarUrl
        case movieId
        case title
        case releaseYear
        case posterUrl
        case rating
        case reviewText
        case isSpoiler
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = (try? c.decode(String.self, forKey: .type)) ?? "activity"
        occurredAt = try? c.decodeIfPresent(String.self, forKey: .occurredAt)
        userId = c.homeFlexibleInt(.userId) ?? 0
        username = (try? c.decode(String.self, forKey: .username)) ?? "member"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        movieId = c.homeFlexibleInt(.movieId) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        releaseYear = c.homeFlexibleInt(.releaseYear)
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        rating = c.homeFlexibleDouble(.rating)
        reviewText = try? c.decodeIfPresent(String.self, forKey: .reviewText)
        isSpoiler = try? c.decodeIfPresent(Bool.self, forKey: .isSpoiler)
    }

    var asMovie: Movie {
        Movie(
            id: movieId,
            title: title,
            releaseYear: releaseYear,
            posterUrl: posterUrl
        )
    }
}

private struct HomeReviewItem: Decodable, Identifiable {
    let id: Int
    let userId: Int
    let username: String
    let avatarUrl: String?
    let movieId: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?
    let content: String
    let isSpoiler: Bool
    let rating: Double?
    let likeCount: Int
    let commentCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case avatarUrl
        case movieId
        case title
        case releaseYear
        case posterUrl
        case content
        case isSpoiler
        case rating
        case likeCount
        case commentCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.homeFlexibleInt(.id) ?? 0
        userId = c.homeFlexibleInt(.userId) ?? 0
        username = (try? c.decode(String.self, forKey: .username)) ?? "member"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        movieId = c.homeFlexibleInt(.movieId) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Untitled"
        releaseYear = c.homeFlexibleInt(.releaseYear)
        posterUrl = try? c.decodeIfPresent(String.self, forKey: .posterUrl)
        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        isSpoiler = (try? c.decode(Bool.self, forKey: .isSpoiler)) ?? false
        rating = c.homeFlexibleDouble(.rating)
        likeCount = c.homeFlexibleInt(.likeCount) ?? 0
        commentCount = c.homeFlexibleInt(.commentCount) ?? 0
    }

    var asMovie: Movie {
        Movie(
            id: movieId,
            title: title,
            releaseYear: releaseYear,
            posterUrl: posterUrl
        )
    }
}

private struct HomeListItem: Decodable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let userId: Int
    let username: String
    let avatarUrl: String?
    let movieCount: Int
    let posterUrls: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case userId
        case username
        case avatarUrl
        case movieCount
        case posterUrls
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.homeFlexibleInt(.id) ?? 0
        name = (try? c.decode(String.self, forKey: .name)) ?? "Untitled list"
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        userId = c.homeFlexibleInt(.userId) ?? 0
        username = (try? c.decode(String.self, forKey: .username)) ?? "member"
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        movieCount = c.homeFlexibleInt(.movieCount) ?? 0
        posterUrls = (try? c.decode([String].self, forKey: .posterUrls)) ?? []
    }
}

private extension KeyedDecodingContainer {
    func homeFlexibleInt(_ key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }

        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Int(string ?? "")
        }

        return nil
    }

    func homeFlexibleDouble(_ key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }

        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Double(string ?? "")
        }

        return nil
    }
}

private final class HomeService {
    static let shared = HomeService()
    private init() {}

    func fetchHome() async throws -> HomeResponse {
        try await APIClient.shared.request(
            path: "/home",
            method: .get,
            requiresAuth: true
        )
    }
}
