import SwiftUI
import PhotosUI
import UIKit

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
    @State private var saving = false
    @State private var loadingPhoto = false
    @State private var message: String?

    init(userId: Int, user: User?, onSaved: ((User) -> Void)? = nil) {
        self.userId = userId
        self.initialUser = user
        self.onSaved = onSaved
        _username = State(initialValue: user?.username ?? "")
        _bio = State(initialValue: user?.bio ?? "")
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

                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Spacer()
                            if saving {
                                ProgressView().tint(.black)
                            } else {
                                Text("SAVE CHANGES").font(.subheadline.bold())
                            }
                            Spacer()
                        }
                        .padding(.vertical, 13)
                        .background(AppTheme.green)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .disabled(saving || loadingPhoto || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

            Text("Choose an image from Photos. The image is uploaded to the backend when you save changes.")
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption).foregroundStyle(AppTheme.secondaryText)
            TextField("", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
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
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

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

            // Prvo validiramo/čuvamo tekstualna polja. Ako je username zauzet,
            // avatar se neće bez potrebe uploadovati.
            _ = try await UserService.shared.updateProfile(
                id: userId,
                username: cleanUsername,
                bio: bio
            )

            if let pendingAvatarData {
                _ = try await UserService.shared.uploadAvatar(id: userId, jpegData: pendingAvatarData)
            }

            // Ne prikazujemo "Saved" dok stvarno ne pročitamo profil nazad
            // sa servera. Tako i parent ProfileView odmah dobija novi username/avatar.
            let freshProfile = try await UserService.shared.fetchProfile(id: userId)
            username = freshProfile.username
            bio = freshProfile.bio ?? ""
            self.pendingAvatarData = nil
            onSaved?(freshProfile)
            await authViewModel.refreshCurrentUser()
            message = "Saved"
        } catch {
            message = error.localizedDescription
        }
    }
}
