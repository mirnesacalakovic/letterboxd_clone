import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var vm: ProfileViewModel
    @State private var showLogoutConfirm = false

    init(userId: Int, isOwnProfile: Bool = true) {
        _vm = StateObject(wrappedValue: ProfileViewModel(userId: userId, isOwnProfile: isOwnProfile))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        profileTabs

                        if vm.isLoading && vm.profile == nil {
                            ProgressView().tint(AppTheme.green).frame(maxWidth: .infinity).padding(.top, 60)
                        } else if let error = vm.errorMessage, vm.profile == nil {
                            Text(error).foregroundStyle(.red).font(.footnote)
                        } else {
                            ProfileOverviewTab(vm: vm)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(vm.profile?.username ?? authViewModel.currentUser?.username ?? "Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                if vm.isOwnProfile {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink(destination: SettingsView(userId: vm.userId, user: vm.profile) { updated in
                            vm.profile = updated
                        }) {
                            Image(systemName: "gearshape").foregroundStyle(.white)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.isOwnProfile {
                        Menu {
                            Button("Log out", role: .destructive) { showLogoutConfirm = true }
                        } label: {
                            Image(systemName: "ellipsis").foregroundStyle(.white)
                        }
                    }
                }
            }
            .alert("Log out?", isPresented: $showLogoutConfirm) {
                Button("Log out", role: .destructive) { authViewModel.logout() }
                Button("Cancel", role: .cancel) { }
            }
            .refreshable {
                await vm.loadAll()
                await vm.loadFollowState(currentUserId: authViewModel.currentUser?.id)
            }
            .task {
                await vm.loadAll()
                await vm.loadFollowState(currentUserId: authViewModel.currentUser?.id)
            }
            .onReceive(NotificationCenter.default.publisher(for: .diaryDidChange)) { _ in
                Task { await vm.loadAll() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .listsDidChange)) { _ in
                guard vm.isOwnProfile else { return }
                Task { await vm.loadAll() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .followRelationshipDidChange)) { _ in
                guard vm.isOwnProfile else { return }
                Task { await vm.loadAll() }
            }
        }
    }

    private var profileTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Profile")
                    .font(.subheadline.bold())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(AppTheme.green)
                    .clipShape(Capsule())

                NavigationLink(destination: ProfileSectionView(section: .diary, userId: vm.userId, isOwnProfile: vm.isOwnProfile)) {
                    pill("Diary")
                }
                NavigationLink(destination: ProfileSectionView(section: .lists, userId: vm.userId, isOwnProfile: vm.isOwnProfile)) {
                    pill("Lists")
                }
                NavigationLink(destination: ProfileSectionView(section: .watchlist, userId: vm.userId, isOwnProfile: vm.isOwnProfile)) {
                    pill("Watchlist")
                }
            }
        }
    }

    private func pill(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(AppTheme.cardBackground)
            .clipShape(Capsule())
    }
}
