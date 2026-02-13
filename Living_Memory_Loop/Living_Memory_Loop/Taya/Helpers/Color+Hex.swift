import SwiftUI

extension Color {
    init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "#", with: "")

        var parsed: UInt64 = 0
        Scanner(string: value).scanHexInt64(&parsed)

        let a, r, g, b: UInt64
        switch value.count {
        case 3:
            a = 255
            r = ((parsed >> 8) & 0xF) * 17
            g = ((parsed >> 4) & 0xF) * 17
            b = (parsed & 0xF) * 17
        case 6:
            a = 255
            r = (parsed >> 16) & 0xFF
            g = (parsed >> 8) & 0xFF
            b = parsed & 0xFF
        case 8:
            a = (parsed >> 24) & 0xFF
            r = (parsed >> 16) & 0xFF
            g = (parsed >> 8) & 0xFF
            b = parsed & 0xFF
        default:
            a = 255
            r = 0
            g = 0
            b = 0
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
