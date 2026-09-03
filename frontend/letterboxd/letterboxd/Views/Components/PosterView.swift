import SwiftUI

struct PosterView: View {
    let url: String?
    var width: CGFloat = 95
    var height: CGFloat = 142

    var body: some View {
        AsyncImage(url: url.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default:
                ZStack {
                    AppTheme.cardBackground
                    Image(systemName: "film").font(.title).foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
