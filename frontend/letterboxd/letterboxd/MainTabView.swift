import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            HomeView().tabItem { Label("Home", systemImage: "house.fill") }
            SearchView().tabItem { Label("Search", systemImage: "magnifyingglass") }
            LogView().tabItem { Label("Log", systemImage: "plus.circle.fill") }
            ActivityView().tabItem { Label("Activity", systemImage: "bolt.fill") }
            // userId ide direktno iz authViewModel (uvek popunjen dok je
            // MainTabView na ekranu, jer ContentView prelazi ovde tek
            // kad je isAuthenticated == true) — ovo je fix za poznati bug
            // iz handoff dokumenta (profil je ranije koristio SAMO
            // authViewModel.currentUser bez pravog GET /api/users/:id poziva).
            ProfileView(userId: authViewModel.currentUser?.id ?? 0, isOwnProfile: true)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(AppTheme.green)
    }
}
