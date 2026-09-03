import Foundation

// Tela zahteva koja backend očekuje (camelCase, videti
// authController.js — req.body destructuring).
private struct RegisterBody: Encodable {
    let username: String
    let email: String
    let password: String
}

private struct LoginBody: Encodable {
    let email: String
    let password: String
}

private struct UserResponse: Decodable {
    let user: User
}

final class AuthService {
    static let shared = AuthService()
    private init() {}

    func register(username: String, email: String, password: String) async throws -> User {
        let body = RegisterBody(username: username, email: email, password: password)
        let response: AuthResponse = try await APIClient.shared.request(
            path: "/auth/register", method: .post, body: body, requiresAuth: false
        )
        KeychainHelper.saveToken(response.token)
        return response.user
    }

    func login(email: String, password: String) async throws -> User {
        let body = LoginBody(email: email, password: password)
        let response: AuthResponse = try await APIClient.shared.request(
            path: "/auth/login", method: .post, body: body, requiresAuth: false
        )
        KeychainHelper.saveToken(response.token)
        return response.user
    }

    // Koristi se pri pokretanju app-a da proveri da li sačuvani token
    // (iz prethodne sesije) i dalje važi.
    func fetchCurrentUser() async throws -> User {
        let response: UserResponse = try await APIClient.shared.request(
            path: "/auth/me", method: .get
        )
        return response.user
    }

    func logout() {
        // Backend logout endpoint postoji radi konzistentnosti API-ja
        // (JWT je stateless — server ne mora ništa da obriše), ali
        // lokalno brisanje tokena je ono što stvarno "odjavljuje".
        KeychainHelper.deleteToken()
    }
}
