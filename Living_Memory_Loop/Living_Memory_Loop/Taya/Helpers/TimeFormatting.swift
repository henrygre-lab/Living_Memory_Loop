import Foundation

enum TimeFormatting {
    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func timeAgo(from date: Date, now: Date = .now) -> String {
        let diff = max(0, now.timeIntervalSince(date))
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3_600)
        let days = Int(diff / 86_400)

        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        if days < 7 { return "\(days)d ago" }
        return monthDayFormatter.string(from: date)
    }
}
