import Foundation

struct UsageWindow: Codable, Equatable, Sendable {
    let usedPercent: Double
    let windowMinutes: Int?
    let resetsAt: Date?

    var remainingPercent: Double {
        min(max(0, 100 - usedPercent), 100)
    }

    var remainingRatio: Double {
        min(1, max(0, remainingPercent / 100))
    }

    enum CodingKeys: String, CodingKey {
        case usedPercent
        case windowMinutes = "window_duration_mins"
        case resetsAt = "resets_at"
    }
}

struct UsageSnapshot: Equatable, Sendable {
    let primary: UsageWindow   // 5-hour window
    let secondary: UsageWindow // weekly window
    let fetchedAt: Date
}

enum UsageError: Error, Equatable, Sendable {
    case cliNotFound
    case notAuthenticated
    case rpcFailed(String)
    case decodeFailed(String)
    case incompatibleResponse(String)
}
