import Foundation
internal import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Poziva se jednom pri pokretanju app-a (videti CineTrackApp.swift)
    // da proveri da li sačuvani token iz Keychain-a i dalje važi.
    func restoreSession() async {
        guard KeychainHelper.getToken() != nil else {
            isAuthenticated = false
            return
        }
        isLoading = true
        do {
            currentUser = try await AuthService.shared.fetchCurrentUser()
            isAuthenticated = true
        } catch {
            // Token postoji ali je nevažeći/istekao — očisti ga.
            KeychainHelper.deleteToken()
            isAuthenticated = false
        }
        isLoading = false
    }

    func register(username: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await AuthService.shared.register(username: username, email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await AuthService.shared.login(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshCurrentUser() async {
        guard isAuthenticated else { return }
        do {
            currentUser = try await AuthService.shared.fetchCurrentUser()
        } catch {
            // Settings save je već potvrđen preko /users/:id; neuspeh ovog
            // pomoćnog refresh-a ne treba da odjavi korisnika niti poništi save.
        }
    }

    func logout() {
        AuthService.shared.logout()
        currentUser = nil
        isAuthenticated = false
    }
}
