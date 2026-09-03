import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading && authViewModel.currentUser == nil {
                ZStack { AppTheme.background.ignoresSafeArea(); ProgressView("Loading...").tint(.white).foregroundStyle(.white) }
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
        .task { await authViewModel.restoreSession() }
    }
}
