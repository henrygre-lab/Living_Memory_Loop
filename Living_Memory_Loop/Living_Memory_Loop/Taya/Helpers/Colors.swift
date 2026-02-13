import SwiftUI

enum AppColors {
    struct CategoryStyle {
        let background: Color
        let text: Color
    }

    static let background = Color(hex: "#F0F8FF")
    static let backgroundPure = Color(hex: "#FFFFFF")
    static let backgroundSecondary = Color(hex: "#E8F1FA")
    static let backgroundTertiary = Color(hex: "#D6E6F5")

    static let text = Color(hex: "#000000")
    static let textSecondary = Color(hex: "#2C3E50")
    static let textTertiary = Color(hex: "#4682B4")

    static let navy = Color(hex: "#001F54")
    static let steelBlue = Color(hex: "#4682B4")
    static let turquoise = Color(hex: "#40E0D0")
    static let lightBlue = Color(hex: "#ADD8E6")

    static let border = Color(hex: "#C8DDF0")
    static let borderLight = Color(hex: "#DDE9F4")
    static let cardBg = Color(hex: "#F5FAFF")

    static let danger = Color(hex: "#E53935")
    static let pinColor = Color(hex: "#D4AF37")

    static let categoryStyles: [String: CategoryStyle] = [
        "Shopping": .init(background: Color(hex: "#FFF8E1"), text: Color(hex: "#F57F17")),
        "Learning": .init(background: Color(hex: "#E0F2F1"), text: Color(hex: "#00796B")),
        "Meeting": .init(background: Color(hex: "#E3F2FD"), text: Color(hex: "#1565C0")),
        "Personal": .init(background: Color(hex: "#EDE7F6"), text: Color(hex: "#5E35B1")),
        "Ideas": .init(background: Color(hex: "#FFF3E0"), text: Color(hex: "#E65100")),
        "Health": .init(background: Color(hex: "#E0F7FA"), text: Color(hex: "#00838F")),
        "Work": .init(background: Color(hex: "#E8EAF6"), text: Color(hex: "#283593")),
        "Travel": .init(background: Color(hex: "#E0F2F1"), text: Color(hex: "#00695C")),
        "Other": .init(background: Color(hex: "#ECEFF1"), text: Color(hex: "#546E7A")),
    ]

    static let moodColors: [String: Color] = [
        "reflective": Color(hex: "#5C6BC0"),
        "excited": Color(hex: "#FF7043"),
        "urgent": Color(hex: "#E53935"),
        "calm": Color(hex: "#26A69A"),
        "curious": Color(hex: "#42A5F5"),
        "grateful": Color(hex: "#7E57C2"),
        "determined": Color(hex: "#FF8F00"),
        "nostalgic": Color(hex: "#8D6E63"),
        "creative": Color(hex: "#EC407A"),
        "neutral": Color(hex: "#78909C"),
    ]

    static func categoryStyle(for category: String) -> CategoryStyle {
        categoryStyles[category] ?? categoryStyles["Other"]!
    }

    static func moodColor(for mood: String) -> Color {
        moodColors[mood.lowercased()] ?? moodColors["neutral"]!
    }
}
