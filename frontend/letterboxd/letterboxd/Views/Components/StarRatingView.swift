import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Double
    var interactive = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { value in
                Image(systemName: Double(value) <= rating ? "star.fill" : "star")
                    .foregroundStyle(AppTheme.green)
                    .font(.title3)
                    .onTapGesture { if interactive { rating = Double(value) } }
            }
        }
    }
}
