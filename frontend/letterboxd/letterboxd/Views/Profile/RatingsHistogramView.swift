import SwiftUI

// Letterboxd-style ratings distribution used on the profile and Stats screen.
// The histogram always contains the ten half-star buckets from 0.5 through 5.0.
// Touch/drag across the bars (or hover with a pointer in Simulator/iPad) reveals
// the exact number of ratings in the selected bucket.
struct RatingsHistogramView: View {
    let distribution: [RatingBucket]
    let averageRating: Double?

    @State private var selectedRating: Double?

    private static let allValues: [Double] =
        stride(from: 0.5, through: 5.0, by: 0.5).map { $0 }

    private var buckets: [(rating: Double, count: Int)] {
        Self.allValues.map { value in
            let count = distribution.first {
                abs($0.rating - value) < 0.001
            }?.count ?? 0

            return (value, count)
        }
    }

    private var maxCount: Int {
        max(buckets.map(\.count).max() ?? 0, 1)
    }

    private var totalRatings: Int {
        buckets.reduce(0) { $0 + $1.count }
    }

    // Use the exact same buckets that draw the histogram to calculate the
    // displayed average. This keeps the number visually/semantically in sync
    // with the graph even if a stale API summary value ever slips through.
    private var histogramAverage: Double? {
        guard totalRatings > 0 else {
            return averageRating
        }

        let weightedTotal = buckets.reduce(0.0) { partial, bucket in
            partial + bucket.rating * Double(bucket.count)
        }

        return weightedTotal / Double(totalRatings)
    }

    private var selectedBucket: (rating: Double, count: Int)? {
        guard let selectedRating else {
            return nil
        }

        return buckets.first {
            abs($0.rating - selectedRating) < 0.001
        }
    }

    var body: some View {
        VStack(spacing: 7) {
            summaryLabel

            HStack(alignment: .bottom, spacing: 7) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.green)
                    .padding(.bottom, 1)

                histogram

                HStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
                .foregroundStyle(AppTheme.green)
                .padding(.bottom, 1)
            }
            .frame(height: 48, alignment: .bottom)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ratings distribution")
    }

    // At rest this makes the average understandable instead of showing a bare
    // decimal next to five stars. Selecting a bar temporarily replaces it with
    // that bucket's exact rating + count.
    @ViewBuilder
    private var summaryLabel: some View {
        if let bucket = selectedBucket {
            Text("\(ratingText(bucket.rating)) ★  ·  \(countText(bucket.count))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.cardBackground)
                .clipShape(Capsule())
                .transition(.opacity)
        } else if let average = histogramAverage {
            Text("Average \(String(format: "%.1f", average))  ·  \(countText(totalRatings))")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var histogram: some View {
        GeometryReader { geometry in
            let barCount = CGFloat(buckets.count)
            let spacing: CGFloat = 4
            let availableWidth = max(
                geometry.size.width - spacing * (barCount - 1),
                1
            )
            let barWidth = availableWidth / barCount

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(buckets, id: \.rating) { bucket in
                    let isSelected = selectedRating.map {
                        abs($0 - bucket.rating) < 0.001
                    } ?? false

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(
                            barColor(
                                count: bucket.count,
                                isSelected: isSelected
                            )
                        )
                        .frame(
                            width: barWidth,
                            height: barHeight(for: bucket.count)
                        )
                        // A larger invisible hit area keeps even tiny/empty bars
                        // easy to select with a finger.
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.12)) {
                                selectedRating = bucket.rating
                            }
                        }
                        .onHover { hovering in
                            withAnimation(.easeOut(duration: 0.12)) {
                                if hovering {
                                    selectedRating = bucket.rating
                                } else if selectedRating == bucket.rating {
                                    selectedRating = nil
                                }
                            }
                        }
                        .accessibilityLabel("\(ratingText(bucket.rating)) stars")
                        .accessibilityValue(countText(bucket.count))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        selectBucket(at: value.location.x, width: geometry.size.width)
                    }
            )
        }
    }

    private func selectBucket(at x: CGFloat, width: CGFloat) {
        guard width > 0 else {
            return
        }

        let normalizedX = min(max(x, 0), width - 0.001)
        let fraction = normalizedX / width
        let index = min(
            max(Int(fraction * CGFloat(buckets.count)), 0),
            buckets.count - 1
        )

        let rating = buckets[index].rating

        if selectedRating != rating {
            withAnimation(.easeOut(duration: 0.08)) {
                selectedRating = rating
            }
        }
    }

    private func barHeight(for count: Int) -> CGFloat {
        guard count > 0 else {
            return 3
        }

        let normalized = CGFloat(count) / CGFloat(maxCount)
        return 5 + normalized * 38
    }

    private func barColor(count: Int, isSelected: Bool) -> Color {
        if isSelected {
            return AppTheme.green
        }

        if count == 0 {
            return AppTheme.cardBackground
        }

        return AppTheme.secondaryText.opacity(0.62)
    }

    private func countText(_ count: Int) -> String {
        count == 1 ? "1 rating" : "\(count) ratings"
    }

    private func ratingText(_ rating: Double) -> String {
        let whole = Int(rating)
        let hasHalf = abs(rating - Double(whole) - 0.5) < 0.001

        if hasHalf {
            return whole == 0 ? "½" : "\(whole)½"
        }

        return String(whole)
    }
}
