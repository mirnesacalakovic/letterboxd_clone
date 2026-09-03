import Foundation

// Greške koje API poziv može da vrati — mapiraju se na backend error
// kodove (400/401/403/404/409/500) iz specifikacije.
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, message: String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .noData:
            return "The server returned no data."
        case .decodingError:
            return "Could not process the server response."
        case .serverError(_, let message):
            return message
        case .networkError:
            return "Could not connect to the server. Check your connection and make sure the backend is running."
        }
    }
}

// Oblik greške koju backend vraća: { "error": "poruka" } — videti
// error handling sekciju u svim controller.js fajlovima.
private struct ServerErrorResponse: Decodable {
    let error: String
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// Jedini fajl u aplikaciji koji direktno zove URLSession — svi servisi
// (AuthService, MovieService, itd.) prolaze kroz ovo, isti princip kao
// db.js na backendu (jedna tačka za pristup mreži).
final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    // requiresAuth: da li se šalje Authorization header. Za javne rute
    // (npr. GET /movies) ostavi false; ako je true a token ne postoji,
    // poziv se svejedno šalje bez header-a (backend će vratiti 401 ako
    // je stvarno obavezan).
    func request<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body? = nil,
        requiresAuth: Bool = true
    ) async throws -> Response {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainHelper.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? decoder.decode(ServerErrorResponse.self, from: data))?.error
                ?? "Server error (\(httpResponse.statusCode))"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // Preklapanje za pozive bez tela (GET, DELETE bez body-ja) — da ne
    // moramo svuda da pišemo "body: EmptyBody? = nil".
    func request<Response: Decodable>(
        path: String,
        method: HTTPMethod,
        requiresAuth: Bool = true
    ) async throws -> Response {
        try await request(path: path, method: method, body: Optional<EmptyBody>.none, requiresAuth: requiresAuth)
    }

    // Binary upload za profilnu sliku. Avatar se šalje kao pravi JPEG/PNG
    // body, a ne kao URL string ili base64 unutar JSON-a.
    func uploadBinary<Response: Decodable>(
        path: String,
        data: Data,
        contentType: String,
        requiresAuth: Bool = true
    ) async throws -> Response {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainHelper.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = data

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? decoder.decode(ServerErrorResponse.self, from: responseData))?.error
                ?? "Server error (\(httpResponse.statusCode))"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        do {
            return try decoder.decode(Response.self, from: responseData)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// Prazan Encodable za pozive bez tela zahteva.
struct EmptyBody: Encodable {}
