import SwiftUI

enum AppFonts {
    static let interRegular = "Inter-Regular"
    static let interMedium = "Inter-Medium"
    static let interSemiBold = "Inter-SemiBold"
    static let interBold = "Inter-Bold"
}

enum AppTypography {
    static let brand = Font.custom(AppFonts.interBold, size: 28)
    static let tagline = Font.custom(AppFonts.interMedium, size: 10)
    static let title = Font.custom(AppFonts.interSemiBold, size: 20)
    static let cardTitle = Font.custom(AppFonts.interBold, size: 18)
    static let cardCategory = Font.custom(AppFonts.interSemiBold, size: 10)
    static let cardAction = Font.custom(AppFonts.interRegular, size: 14)
    static let cardMore = Font.custom(AppFonts.interMedium, size: 12)
    static let cardMeta = Font.custom(AppFonts.interRegular, size: 12)
    static let cardMood = Font.custom(AppFonts.interRegular, size: 12)
    static let body = Font.custom(AppFonts.interRegular, size: 14)
    static let emptyTitle = Font.custom(AppFonts.interSemiBold, size: 18)
}
