import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    let userId: Int
    let initialUser: User?
    let onSaved: ((User) -> Void)?

    @State private var username: String
    @State private var bio: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingAvatarData: Data?
    @State private var previewImage: UIImage?

    @State private var favoriteMovies: [FavoriteMovie]
    @State private var favoriteQuery = ""
    @State private var favoriteSearchResults: [Movie] = []
    @State private var isSearchingFavorites = false
    @State private var favoritesLoaded = false
    @State private var draggedFavoriteId: Int?

    @State private var saving = false
    @State private var loadingPhoto = false
    @State private var message: String?

    init(userId: Int, user: User?, onSaved: ((User) -> Void)? = nil) {
        self.userId = userId
        self.initialUser = user
        self.onSaved = onSaved
        _username = State(initialValue: user?.username ?? "")
        _bio = State(initialValue: user?.bio ?? "")
        _favoriteMovies = State(initialValue: user?.favoriteMovies ?? [])
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("PROFILE")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.secondaryText)

                    avatarPicker
                    field("Username", text: $username)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Bio")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                        TextEditor(text: $bio)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 110)
                            .padding(8)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                    }

                    favoriteFilmsSection

                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Spacer()

                            if saving {
                                ProgressView().tint(.black)
                            } else {
                                Text("SAVE CHANGES")
                                    .font(.subheadline.bold())
                            }

                            Spacer()
                        }
                        .padding(.vertical, 13)
                        .background(AppTheme.green)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .disabled(
                        saving ||
                        loadingPhoto ||
                        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                    .opacity((saving || loadingPhoto) ? 0.65 : 1)

                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(message == "Saved" ? AppTheme.green : .red)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task { await loadSelectedPhoto(newItem) }
        }
        .task {
            await loadFavoriteMoviesIfNeeded()
        }
        .task(id: favoriteQuery) {
            await searchFavoriteMovies()
        }
    }

    private var avatarPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Avatar")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)

            HStack(spacing: 16) {
                Group {
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        AsyncImage(url: APIConfig.mediaURL(for: initialUser?.avatarUrl)) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.cardBackground, lineWidth: 2))

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 7) {
                        Image(systemName: "photo")
                        Text(previewImage == nil ? "CHOOSE PHOTO" : "CHANGE PHOTO")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                if loadingPhoto {
                    ProgressView().tint(AppTheme.green)
                }
            }

            Text("Choose an image from Photos. The image is uploaded when you save changes.")
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var favoriteFilmsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FAVORITE FILMS")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.secondaryText)

                Text("Choose up to four films. Drag the rows to change their order.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if favoriteMovies.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "heart")
                        .foregroundStyle(AppTheme.secondaryText)

                    Text("No favorite films selected yet.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(favoriteMovies.enumerated()), id: \.element.movieId) { index, favorite in
                        favoriteRow(favorite, index: index)
                            .onDrag {
                                draggedFavoriteId = favorite.movieId
                                return NSItemProvider(object: String(favorite.movieId) as NSString)
                            }
                            .onDrop(
                                of: [UTType.text],
                                delegate: FavoriteMovieDropDelegate(
                                    targetMovieId: favorite.movieId,
                                    favorites: $favoriteMovies,
                                    draggedMovieId: $draggedFavoriteId
                                )
                            )

                        if index < favoriteMovies.count - 1 {
                            Divider()
                                .overlay(Color.white.opacity(0.08))
                        }
                    }
                }
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if favoriteMovies.count < 4 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.secondaryText)

                        TextField("Search films to add", text: $favoriteQuery)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)

                        if !favoriteQuery.isEmpty {
                            Button {
                                favoriteQuery = ""
                                favoriteSearchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if isSearchingFavorites {
                        HStack {
                            Spacer()
                            ProgressView().tint(AppTheme.green)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if !favoriteSearchResults.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(favoriteSearchResults.prefix(6)) { movie in
                                Button {
                                    addFavorite(movie)
                                } label: {
                                    HStack(spacing: 11) {
                                        PosterView(
                                            url: movie.posterUrl,
                                            width: 38,
                                            height: 57
                                        )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(movie.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)

                                            if let year = movie.releaseYear {
                                                Text(String(year))
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.secondaryText)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(AppTheme.green)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .overlay(Color.white.opacity(0.08))
                            }
                        }
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else {
                Text("You have selected the maximum of four favorite films. Remove one to add another.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func favoriteRow(_ favorite: FavoriteMovie, index: Int) -> some View {
        HStack(spacing: 11) {
            Image(systemName: "line.3.horizontal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 22)

            PosterView(
                url: favorite.posterUrl,
                width: 42,
                height: 63
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("#\(index + 1)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.green)

                Text(favorite.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let year = favorite.releaseYear {
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Spacer()

            Button {
                removeFavorite(movieId: favorite.movieId)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(favorite.title) from favorites")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)

            TextField("", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
        }
    }

    private func addFavorite(_ movie: Movie) {
        guard favoriteMovies.count < 4 else { return }
        guard !favoriteMovies.contains(where: { $0.movieId == movie.id }) else { return }

        favoriteMovies.append(
            FavoriteMovie(
                position: favoriteMovies.count + 1,
                movieId: movie.id,
                title: movie.title,
                releaseYear: movie.releaseYear,
                posterUrl: movie.posterUrl
            )
        )

        favoriteQuery = ""
        favoriteSearchResults = []
    }

    private func removeFavorite(movieId: Int) {
        withAnimation(.easeInOut(duration: 0.18)) {
            favoriteMovies.removeAll { $0.movieId == movieId }
        }
    }

    @MainActor
    private func loadFavoriteMoviesIfNeeded() async {
        guard !favoritesLoaded else { return }
        favoritesLoaded = true

        do {
            let freshProfile = try await UserService.shared.fetchProfile(id: userId)
            favoriteMovies = freshProfile.favoriteMovies ?? []
        } catch {
            // The settings screen can still use the favorites supplied by ProfileView.
        }
    }

    @MainActor
    private func searchFavoriteMovies() async {
        let query = favoriteQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.count >= 2 else {
            favoriteSearchResults = []
            isSearchingFavorites = false
            return
        }

        do {
            try await Task.sleep(nanoseconds: 250_000_000)
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        isSearchingFavorites = true
        defer { isSearchingFavorites = false }

        do {
            let results = try await MovieService.shared.search(query, limit: 12)
            guard favoriteQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query else {
                return
            }

            favoriteSearchResults = results.filter { movie in
                !favoriteMovies.contains(where: { $0.movieId == movie.id })
            }
        } catch {
            guard !Task.isCancelled else { return }
            favoriteSearchResults = []
        }
    }

    @MainActor
    private func loadSelectedPhoto(_ item: PhotosPickerItem) async {
        loadingPhoto = true
        message = nil
        defer { loadingPhoto = false }

        do {
            guard let rawData = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: rawData),
                  let jpegData = resizedJPEGData(from: image) else {
                message = "Couldn’t read that image."
                return
            }

            previewImage = UIImage(data: jpegData)
            pendingAvatarData = jpegData
        } catch {
            message = "Couldn’t load image: \(error.localizedDescription)"
        }
    }

    private func resizedJPEGData(from image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1200
        let longestSide = max(image.size.width, image.size.height)
        let scale = longestSide > maxDimension ? maxDimension / longestSide : 1
        let targetSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let rendered: UIImage
        if scale < 1 {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            rendered = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        } else {
            rendered = image
        }

        return rendered.jpegData(compressionQuality: 0.82)
    }

    @MainActor
    private func save() async {
        saving = true
        message = nil
        defer { saving = false }

        do {
            let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

            _ = try await UserService.shared.updateProfile(
                id: userId,
                username: cleanUsername,
                bio: bio
            )

            _ = try await UserService.shared.setFavorites(
                userId: userId,
                movieIds: favoriteMovies.map(\.movieId)
            )

            if let pendingAvatarData {
                _ = try await UserService.shared.uploadAvatar(
                    id: userId,
                    jpegData: pendingAvatarData
                )
            }

            let freshProfile = try await UserService.shared.fetchProfile(id: userId)
            username = freshProfile.username
            bio = freshProfile.bio ?? ""
            favoriteMovies = freshProfile.favoriteMovies ?? []
            pendingAvatarData = nil

            onSaved?(freshProfile)
            await authViewModel.refreshCurrentUser()
            message = "Saved"
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct FavoriteMovieDropDelegate: DropDelegate {
    let targetMovieId: Int
    @Binding var favorites: [FavoriteMovie]
    @Binding var draggedMovieId: Int?

    func dropEntered(info: DropInfo) {
        guard let draggedMovieId,
              draggedMovieId != targetMovieId,
              let fromIndex = favorites.firstIndex(where: { $0.movieId == draggedMovieId }),
              let toIndex = favorites.firstIndex(where: { $0.movieId == targetMovieId }) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            favorites.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedMovieId = nil
        return true
    }
}
