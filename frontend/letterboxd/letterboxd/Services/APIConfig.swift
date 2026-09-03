import Foundation

enum APIConfig {
    // Promeni SAMO serverURL ako backend nije na istom Mac-u kao Simulator.
    // Primer za backend na Windows računaru u istoj mreži:
    // static let serverURL = "http://192.168.1.42:3000"
    static let serverURL = "http://localhost:3000"
    static let baseURL = serverURL + "/api"

    // Seedovani korisnici mogu imati puni https URL (DiceBear), dok novi
    // avatar upload sa našeg backenda vraća relativnu /uploads/... putanju.
    // Ova funkcija podržava oba slučaja.
    static func mediaURL(for value: String?) -> URL? {
        guard let value, !value.isEmpty else { return nil }
        if let absolute = URL(string: value), absolute.scheme != nil {
            return absolute
        }
        let path = value.hasPrefix("/") ? value : "/" + value
        return URL(string: serverURL + path)
    }
}
