import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var vm = ActivityViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    activityTabs
                        .padding(.horizontal, 14)
                        .padding(.top, 6)
                        .padding(.bottom, 8)

                    Divider().overlay(AppTheme.cardBackground)

                    content
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .onReceive(NotificationCenter.default.publisher(for: .diaryDidChange)) { _ in
                guard vm.selectedTab == .you else { return }
                Task { await vm.load() }
            }
        }
    }

    private var activityTabs: some View {
        HStack(spacing: 2) {
            ForEach(ActivityTab.allCases, id: \.self) { tab in
                Button {
                    Task { await vm.select(tab) }
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(vm.selectedTab == tab ? .white : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(vm.selectedTab == tab ? Color(hex: "#647687") : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color(hex: "#20262C"))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.activities.isEmpty {
            Spacer()
            ProgressView().tint(AppTheme.green)
            Spacer()
        } else if let error = vm.errorMessage, vm.activities.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(AppTheme.orange)
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                Button("Try again") {
                    Task { await vm.load() }
                }
                .foregroundStyle(AppTheme.blue)
            }
            .padding(.horizontal, 30)
            Spacer()
        } else if vm.activities.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.activities) { activity in
                        ActivityRow(
                            activity: activity,
                            currentUserId: authViewModel.currentUser?.id
                        )
                        Divider()
                            .overlay(AppTheme.cardBackground.opacity(0.8))
                            .padding(.leading, 58)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: emptyIcon)
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.secondaryText)

            Text(emptyTitle)
                .font(.headline)
                .foregroundStyle(.white)

            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 38)

            Spacer()
        }
    }

    private var emptyIcon: String {
        switch vm.selectedTab {
        case .friends: return "person.2"
        case .you: return "bolt"
        case .incoming: return "bell"
        }
    }

    private var emptyTitle: String {
        switch vm.selectedTab {
        case .friends: return "No friend activity yet"
        case .you: return "No activity yet"
        case .incoming: return "Nothing incoming yet"
        }
    }

    private var emptyMessage: String {
        switch vm.selectedTab {
        case .friends:
            return "Follow members to see what they watch, rate, review and add to their watchlists."
        case .you:
            return "Your recent watches, ratings, reviews and watchlist additions will appear here."
        case .incoming:
            return "New followers, comments and likes on your reviews will appear here."
        }
    }
}

private struct ActivityRow: View {
    let activity: ActivityItem
    let currentUserId: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                NavigationLink(destination: profileDestination) {
                    avatar
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    header

                    if activity.type == "rating", let rating = activity.rating {
                        CompactStars(rating: rating)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(activity.relativeTime)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.8))
            }

            if shouldShowDetail {
                detail
                    .padding(.leading, 46)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(AppTheme.background)
    }

    private var profileDestination: some View {
        ProfileView(
            userId: activity.userId,
            isOwnProfile: currentUserId == activity.userId
        )
    }

    private var avatar: some View {
        AsyncImage(url: APIConfig.mediaURL(for: activity.avatarUrl)) { phase in
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
        .frame(width: 34, height: 34)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var header: some View {
        switch activity.type {
        case "review":
            Text("\(activity.username) reviewed ")
                .foregroundStyle(AppTheme.secondaryText)
            + movieTitleText

        case "rating":
            Text("\(activity.username) rated ")
                .foregroundStyle(AppTheme.secondaryText)
            + movieTitleText

        case "watched":
            Text("\(activity.username) watched ")
                .foregroundStyle(AppTheme.secondaryText)
            + movieTitleText

        case "watchlist":
            Text("\(activity.username) added ")
                .foregroundStyle(AppTheme.secondaryText)
            + movieTitleText
            + Text(" to their watchlist")
                .foregroundStyle(AppTheme.secondaryText)

        case "review_like":
            Text("\(activity.username) liked your review of ")
                .foregroundStyle(AppTheme.secondaryText)
            + movieTitleText

        case "comment":
            Text("\(activity.username) replied to your review of ")
                .foregroundStyle(AppTheme.secondaryText)
            + movieTitleText

        case "follow":
            Text("\(activity.username)")
                .foregroundStyle(.white)
                .bold()
            + Text(" started following you")
                .foregroundStyle(AppTheme.secondaryText)

        default:
            Text(activity.username)
                .foregroundStyle(.white)
                .bold()
        }
    }

    private var movieTitleText: Text {
        Text(movieLabel)
            .foregroundStyle(.white)
            .bold()
    }

    private var movieLabel: String {
        guard let title = activity.title else { return "a film" }
        if let year = activity.releaseYear {
            return "\(title) \(year)"
        }
        return title
    }

    private var shouldShowDetail: Bool {
        activity.movie != nil && (
            activity.type == "review" ||
            activity.type == "watched" ||
            activity.type == "review_like" ||
            activity.type == "comment"
        )
    }

    @ViewBuilder
    private var detail: some View {
        if let movie = activity.movie {
            NavigationLink(destination: MovieDetailView(movie: movie)) {
                HStack(alignment: .top, spacing: 10) {
                    PosterView(url: activity.posterUrl, width: 48, height: 72)

                    VStack(alignment: .leading, spacing: 5) {
                        if let rating = activity.rating, rating > 0 {
                            CompactStars(rating: rating)
                        }

                        if let text = detailText, !text.isEmpty {
                            if activity.isSpoiler == true && activity.type != "comment" {
                                Label("Contains spoilers", systemImage: "eye.slash")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            } else {
                                Text(text)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineLimit(4)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var detailText: String? {
        guard let text = activity.extra?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }
}

private struct CompactStars: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: symbol(for: star))
                    .font(.caption)
                    .foregroundStyle(AppTheme.green)
            }
        }
    }

    private func symbol(for star: Int) -> String {
        let lowerBound = Double(star - 1)
        let upperBound = Double(star)

        if rating >= upperBound { return "star.fill" }
        if rating > lowerBound { return "star.leadinghalf.filled" }
        return "star"
    }
}
