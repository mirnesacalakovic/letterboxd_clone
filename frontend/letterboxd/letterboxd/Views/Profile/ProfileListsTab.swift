import SwiftUI

struct ProfileListsTab: View {
    let lists: [MovieListSummary]

    var body: some View {
        if lists.isEmpty {
            EmptyStateView(
                icon: "square.stack",
                title: "No lists yet",
                subtitle: "Lists you create will appear here."
            )
        } else {
            VStack(spacing: 0) {
                ForEach(lists) { list in
                    ProfileListPreviewRow(list: list)
                }
            }
        }
    }
}

struct ProfileListPreviewRow: View {
    let list: MovieListSummary

    @State private var detail: MovieListDetail?
    @State private var didLoad = false

    var body: some View {
        NavigationLink {
            MovieListDetailView(
                listId: list.id,
                title: list.name
            )
        } label: {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(list.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if !list.isPublic {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.28))
                }

                if let description = list.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                posterStrip

                if let detail {
                    Text("\(detail.movies.count) \(detail.movies.count == 1 ? "FILM" : "FILMS")")
                        .font(.caption2.weight(.bold))
                        .tracking(0.5)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .task {
            await loadDetail()
        }

        Divider()
            .overlay(AppTheme.cardBackground)
    }

    @ViewBuilder
    private var posterStrip: some View {
        if let detail, !detail.movies.isEmpty {
            HStack(spacing: 6) {
                ForEach(Array(detail.movies.prefix(6))) { movie in
                    PosterView(
                        url: movie.posterUrl,
                        width: 48,
                        height: 72
                    )
                }

                Spacer(minLength: 0)
            }
        } else if didLoad {
            RoundedRectangle(cornerRadius: 6)
                .fill(AppTheme.cardBackground)
                .frame(height: 72)
                .overlay {
                    HStack(spacing: 7) {
                        Image(systemName: "rectangle.stack")
                        Text("No films in this list")
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                }
        } else {
            HStack(spacing: 6) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(AppTheme.cardBackground)
                        .frame(width: 48, height: 72)
                }

                Spacer(minLength: 0)
            }
            .redacted(reason: .placeholder)
        }
    }

    @MainActor
    private func loadDetail() async {
        guard !didLoad else { return }

        do {
            detail = try await UserService.shared.fetchListDetail(id: list.id)
        } catch {
            detail = nil
        }

        didLoad = true
    }
}
