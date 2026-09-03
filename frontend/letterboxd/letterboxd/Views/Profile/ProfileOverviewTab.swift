import SwiftUI

struct ProfileOverviewTab: View {
    @ObservedObject var vm: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            header
            if let favorites = vm.profile?.favoriteMovies, !favorites.isEmpty {
                section(title: "FAVORITES") {
                    posterGrid(favorites.map { PosterGridItem(id: $0.movieId, title: $0.title, posterUrl: $0.posterUrl, releaseYear: $0.releaseYear) })
                }
            }
            if !vm.recentActivity.isEmpty {
                section(title: "RECENT ACTIVITY") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            ForEach(vm.recentActivity) { entry in
                                NavigationLink(destination: MovieDetailView(movie: entry.asMovie)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        PosterView(url: entry.posterUrl, width: 78, height: 117)
                                        HStack(spacing: 3) {
                                            if let rating = entry.rating { MiniStars(rating: rating) }
                                            if entry.isRewatch {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(AppTheme.secondaryText)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        NavigationLink(destination: ProfileSectionView(section: .diary, userId: vm.userId, isOwnProfile: vm.isOwnProfile)) {
                            HStack {
                                Text("More activity").font(.subheadline)
                                Image(systemName: "chevron.right").font(.caption2)
                            }
                            .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
            }
            if !vm.ratingsDistribution.isEmpty {
                RatingsHistogramView(distribution: vm.ratingsDistribution, averageRating: vm.averageRating)
            }

            statsRows
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            AsyncImage(url: APIConfig.mediaURL(for: vm.profile?.avatarUrl)) { phase in
                if case .success(let image) = phase { image.resizable().scaledToFill() }
                else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable().foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())

            if let bio = vm.profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline.italic())
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption.bold()).foregroundStyle(AppTheme.secondaryText)
            content()
        }
    }

    private func posterGrid(_ items: [PosterGridItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items) { item in
                    NavigationLink(destination: MovieDetailView(movie: item.asMovie)) {
                        PosterView(url: item.posterUrl, width: 78, height: 117)
                    }
                }
            }
        }
    }

    private var statsRows: some View {
        VStack(spacing: 0) {
            statRow("Films", vm.profile?.watchedCount, section: .films)
            statRow("Diary", vm.diaryCount, section: .diary)
            statRow("Reviews", vm.profile?.reviewCount, section: .reviews)
            statRow("Lists", vm.profile?.listCount, section: .lists)
            statRow("Watchlist", vm.isOwnProfile ? vm.watchlist.count : nil, section: .watchlist)
            statRow("Likes", vm.likeCount, section: .likes)
            statRow("Tags", vm.tagCount, section: .tags)
            statRow("Following", vm.profile?.followingCount, section: .following)
            statRow("Followers", vm.profile?.followersCount, section: .followers)
            statRow("Stats", nil, section: .stats)
        }
    }

    private func statRow(_ label: String, _ value: Int?, section: ProfileSection) -> some View {
        NavigationLink(destination: ProfileSectionView(section: section, userId: vm.userId, isOwnProfile: vm.isOwnProfile)) {
            HStack {
                Text(label).foregroundStyle(.white)
                Spacer()
                Text(String(value ?? 0)).foregroundStyle(AppTheme.secondaryText)
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.vertical, 12)
        }
        .overlay(Divider().overlay(AppTheme.cardBackground), alignment: .bottom)
    }
}

// Zajednički oblik za horizontalni red postera (favorites) — svodi
// FavoriteMovie na isti shape koji koristi NavigationLink → MovieDetailView.
private struct PosterGridItem: Identifiable {
    let id: Int
    let title: String
    let posterUrl: String?
    let releaseYear: Int?

    var asMovie: Movie { Movie(id: id, title: title, releaseYear: releaseYear, posterUrl: posterUrl) }
}

// Kompaktne zvezdice za "Recent activity" red — StarRatingView je
// napravljen za interaktivni unos (veći font, @Binding), ovde treba
// samo sitan read-only prikaz.
struct MiniStars: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: starName(for: index))
                    .font(.system(size: 8))
            }
        }
        .foregroundStyle(AppTheme.green)
    }

    private func starName(for index: Int) -> String {
        let threshold = Double(index) + 1
        if rating >= threshold { return "star.fill" }
        if rating >= threshold - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}
