import Foundation
import XCTest
@testable import Codex_Usage

final class UsageQuotaPresentationTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    func testPrimaryPresentationUsesFullCodexCopyAndTimeReset() throws {
        let now = try date(year: 2026, month: 7, day: 11, hour: 9, minute: 0)
        let reset = try date(year: 2026, month: 7, day: 11, hour: 13, minute: 32)
        let window = UsageWindow(usedPercent: 3, windowMinutes: 300, resetsAt: reset)

        let presentation = UsageQuotaPresentation(
            kind: .primary,
            window: window,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(presentation.title, "5 小时使用限制")
        XCTAssertEqual(presentation.compactLabel, "5h")
        XCTAssertEqual(presentation.remainingText, "剩余 97%")
        XCTAssertEqual(presentation.fullResetText, "将于 13:32 重置")
        XCTAssertEqual(presentation.compactResetText, "13:32")
        XCTAssertEqual(
            presentation.accessibilityText,
            "5 小时使用限制，剩余 97%，将于 13:32 重置"
        )
    }

    func testWeeklyPresentationUsesFullCodexCopyAndDateReset() throws {
        let now = try date(year: 2026, month: 7, day: 11, hour: 9, minute: 0)
        let reset = try date(year: 2026, month: 7, day: 18, hour: 0, minute: 0)
        let window = UsageWindow(usedPercent: 1, windowMinutes: 10_080, resetsAt: reset)

        let presentation = UsageQuotaPresentation(
            kind: .weekly,
            window: window,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(presentation.title, "每周使用限额")
        XCTAssertEqual(presentation.compactLabel, "周")
        XCTAssertEqual(presentation.remainingText, "剩余 99%")
        XCTAssertEqual(presentation.fullResetText, "将于 7月18日 重置")
        XCTAssertEqual(presentation.compactResetText, "7/18")
    }

    func testUnknownAndExpiredResetTimesDoNotShowStaleDates() throws {
        let now = try date(year: 2026, month: 7, day: 11, hour: 9, minute: 0)
        let expired = try date(year: 2026, month: 7, day: 11, hour: 8, minute: 59)

        for reset in [Date?.none, expired] {
            let window = UsageWindow(usedPercent: 50, windowMinutes: 300, resetsAt: reset)
            let presentation = UsageQuotaPresentation(
                kind: .primary,
                window: window,
                now: now,
                calendar: calendar
            )

            XCTAssertEqual(presentation.fullResetText, "重置时间未知")
            XCTAssertEqual(presentation.compactResetText, "—")
        }
    }

    func testRemainingPercentageRoundsToNearestWholeNumber() throws {
        let now = try date(year: 2026, month: 7, day: 11, hour: 9, minute: 0)
        let reset = try date(year: 2026, month: 7, day: 11, hour: 10, minute: 0)
        let window = UsageWindow(usedPercent: 2.4, windowMinutes: 300, resetsAt: reset)

        let presentation = UsageQuotaPresentation(
            kind: .primary,
            window: window,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(presentation.remainingPercent, 98)
        XCTAssertEqual(presentation.remainingRatio, 0.976, accuracy: 0.000_1)
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )))
    }
}
