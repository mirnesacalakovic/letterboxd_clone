import Foundation

// Odgovara redu iz users tabele + agregatima iz findProfileById u
// userModel.js. Polja sa "?" su opciona jer se ne vraćaju u svakom
// kontekstu (npr. register/login vraćaju osnovni User bez brojeva).
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let avatarUrl: String?
    let bio: String?
    let createdAt: String?

    // Prisutno samo u GET /api/users/:id (findProfileById)
    let watchedCount: Int?
    let reviewCount: Int?
    let listCount: Int?
    let followersCount: Int?
    let followingCount: Int?
    let favoriteMovies: [FavoriteMovie]?
}

// Odgovara redu iz user_favorite_movies + join na movies (favoriteModel.js).
struct FavoriteMovie: Codable, Identifiable {
    let position: Int
    let movieId: Int
    let title: String
    let releaseYear: Int?
    let posterUrl: String?

    var id: Int { movieId }
}

// Odgovor na POST /api/auth/register i /login (authController.js).
struct AuthResponse: Codable {
    let user: User
    let token: String
}
