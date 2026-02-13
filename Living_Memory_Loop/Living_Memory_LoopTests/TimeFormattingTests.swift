import XCTest
@testable import Living_Memory_Loop

final class TimeFormattingTests: XCTestCase {
    func testJustNowBoundary() {
        let now = Date(timeIntervalSince1970: 2_000)
        let value = TimeFormatting.timeAgo(from: Date(timeIntervalSince1970: 1_999.7), now: now)
        XCTAssertEqual(value, "Just now")
    }

    func testMinuteHourDayBoundaries() {
        let now = Date(timeIntervalSince1970: 100_000)
        XCTAssertEqual(TimeFormatting.timeAgo(from: now.addingTimeInterval(-120), now: now), "2m ago")
        XCTAssertEqual(TimeFormatting.timeAgo(from: now.addingTimeInterval(-7_200), now: now), "2h ago")
        XCTAssertEqual(TimeFormatting.timeAgo(from: now.addingTimeInterval(-172_800), now: now), "2d ago")
    }

    func testOlderThanSevenDaysFallsBackToMonthDay() {
        let now = Date(timeIntervalSince1970: 200_000)
        let oldDate = now.addingTimeInterval(-(9 * 86_400))
        let value = TimeFormatting.timeAgo(from: oldDate, now: now)
        XCTAssertFalse(value.contains("ago"))
    }
}
