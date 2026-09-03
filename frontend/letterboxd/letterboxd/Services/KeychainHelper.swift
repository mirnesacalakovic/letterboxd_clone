import Foundation
import Security

// Čuva JWT token u iOS Keychain-u — sigurnije od UserDefaults (koji
// nije šifrovan). Isti princip kao "password se ne sme čuvati u plain
// text obliku" iz backend specifikacije, primenjen na token na klijentu.
enum KeychainHelper {
    private static let tokenKey = "com.cinetrack.authToken"

    static func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
        ]
        // Prvo obriši postojeći (ako ga ima), pa upiši novi — Keychain
        // ne dozvoljava direktan "overwrite" istog ključa.
        SecItemDelete(query as CFDictionary)

        var newItem = query
        newItem[kSecValueData as String] = data
        SecItemAdd(newItem as CFDictionary, nil)
    }

    static func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
