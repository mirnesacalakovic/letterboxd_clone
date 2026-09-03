import SwiftUI

struct ProfileDiaryTab: View {
    let entries: [DiaryEntry]

    var body: some View {
        if entries.isEmpty {
            EmptyStateView(icon: "book.closed", title: "No diary entries", subtitle: "Films you log as watched will appear here.")
        } else {
            VStack(spacing: 0) {
                ForEach(entries) { entry in
                    NavigationLink(destination: MovieDetailView(movie: entry.asMovie)) {
                        HStack(alignment: .top, spacing: 14) {
                            PosterView(url: entry.posterUrl, width: 54, height: 81)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.title).font(.subheadline.bold()).foregroundStyle(.white)
                                if let year = entry.releaseYear { Text(String(year)).font(.caption).foregroundStyle(AppTheme.secondaryText) }
                                HStack(spacing: 6) {
                                    if let rating = entry.rating { MiniStars(rating: rating) }
                                    if entry.isRewatch {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 10)).foregroundStyle(AppTheme.secondaryText)
                                    }
                                }
                                if let note = entry.note, !note.isEmpty {
                                    Text(note).font(.caption).foregroundStyle(AppTheme.secondaryText).lineLimit(2)
                                }
                                if let timestamp = formattedTimestamp(for: entry) {
                                    Text(timestamp)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.secondaryText)
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

    private func formattedTimestamp(for entry: DiaryEntry) -> String? {
        let watchedDate = entry.watchedDate.flatMap(Self.parseDate)
        let createdAt = entry.createdAt.flatMap(Self.parseDate)

        guard watchedDate != nil || createdAt != nil else {
            return entry.watchedDate
        }

        let dateText = watchedDate.map(Self.dayFormatter.string)
        let timeText = createdAt.map { Self.timeFormatter.string(from: $0).lowercased() }

        switch (timeText, dateText) {
        case let (time?, date?):
            return "\(time), \(date)"
        case let (time?, nil):
            return time
        case let (nil, date?):
            return date
        default:
            return nil
        }
    }

    private static func parseDate(_ value: String) -> Date? {
        if let date = isoWithFractionalSeconds.date(from: value) {
            return date
        }

        if let date = ISO8601DateFormatter().date(from: value) {
            return date
        }

        return plainDate.date(from: value)
    }

    private static let isoWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plainDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mma"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d.M.yyyy"
        return formatter
    }()

}
