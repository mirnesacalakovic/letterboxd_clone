import SwiftUI

struct ProfileWatchlistTab: View {
    let items: [WatchlistItem]

    private let columns = [GridItem(.adaptive(minimum: 95), spacing: 10)]

    var body: some View {
        if items.isEmpty {
            EmptyStateView(icon: "bookmark", title: "Your watchlist is empty", subtitle: "Films you add to your watchlist will appear here.")
        } else {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(items) { item in
                    NavigationLink(destination: MovieDetailView(movie: item.asMovie)) {
                        VStack(alignment: .leading, spacing: 5) {
                            PosterView(url: item.posterUrl, width: 105, height: 157)
                            Text(item.title).font(.caption.bold()).foregroundStyle(.white).lineLimit(1)
                        }
                    }
                }
            }
        }
    }
}
