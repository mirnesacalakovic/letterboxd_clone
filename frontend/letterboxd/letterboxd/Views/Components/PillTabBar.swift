import SwiftUI

// Isti "pill" tab bar koji Letterboxd koristi svuda gore (Films/Reviews/
// Lists/Journal na Home-u, Profile/Diary/Lists/Watchlist na profilu).
// Generičko po Tab tipu da bi se moglo koristiti na više mesta.
struct PillTabBar<Tab: Hashable>: View {
    let tabs: [(tab: Tab, title: String)]
    @Binding var selection: Tab

    var body: some View {
        HStack(spacing: 2) {
            ForEach(tabs, id: \.tab) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selection = item.tab }
                } label: {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == item.tab ? AppTheme.background : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selection == item.tab ? AppTheme.secondaryText.opacity(0.9) : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
