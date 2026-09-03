import SwiftUI

enum AppTheme {
    static let background = Color(hex: "#14181C")
    static let secondaryBackground = Color(hex: "#1F2428")
    static let cardBackground = Color(hex: "#2C3440")
    static let orange = Color(hex: "#FF8000")
    static let green = Color(hex: "#00E054")
    static let blue = Color(hex: "#40BCF4")
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "#9AB0C3")
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
