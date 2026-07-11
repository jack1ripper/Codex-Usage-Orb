import Foundation

enum UsageQuotaKind: Equatable, Sendable {
    case primary
    case weekly

    var title: String {
        switch self {
        case .primary:
            return "5 小时使用限制"
        case .weekly:
            return "每周使用限额"
        }
    }

    var compactLabel: String {
        switch self {
        case .primary:
            return "5h"
        case .weekly:
            return "周"
        }
    }
}

struct UsageQuotaPresentation: Equatable, Sendable {
    let kind: UsageQuotaKind
    let title: String
    let compactLabel: String
    let remainingPercent: Int
    let remainingRatio: Double
    let remainingText: String
    let fullResetText: String
    let compactResetText: String
    let accessibilityText: String

    init(
        kind: UsageQuotaKind,
        window: UsageWindow,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let remainingPercent = Int(window.remainingPercent.rounded())
        let resetTexts = Self.resetTexts(
            kind: kind,
            resetsAt: window.resetsAt,
            now: now,
            calendar: calendar
        )

        self.kind = kind
        self.title = kind.title
        self.compactLabel = kind.compactLabel
        self.remainingPercent = remainingPercent
        self.remainingRatio = window.remainingRatio
        self.remainingText = "剩余 \(remainingPercent)%"
        self.fullResetText = resetTexts.full
        self.compactResetText = resetTexts.compact
        self.accessibilityText = "\(kind.title)，剩余 \(remainingPercent)%，\(resetTexts.full)"
    }

    private static func resetTexts(
        kind: UsageQuotaKind,
        resetsAt: Date?,
        now: Date,
        calendar: Calendar
    ) -> (full: String, compact: String) {
        guard let resetsAt, resetsAt > now else {
            return ("重置时间未知", "—")
        }

        switch kind {
        case .primary:
            let time = formatted(resetsAt, format: "HH:mm", calendar: calendar)
            return ("将于 \(time) 重置", time)
        case .weekly:
            let date = formatted(resetsAt, format: "M月d日", calendar: calendar)
            let compactDate = formatted(resetsAt, format: "M/d", calendar: calendar)
            return ("将于 \(date) 重置", compactDate)
        }
    }

    private static func formatted(
        _ date: Date,
        format: String,
        calendar: Calendar
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
