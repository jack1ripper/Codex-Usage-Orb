enum UsageDisplayState: Equatable, Sendable {
    case loading
    case data(UsageSnapshot, isStale: Bool)
    case error(UsageError)

    static func resolve(
        snapshot: UsageSnapshot?,
        error: UsageError?
    ) -> UsageDisplayState {
        if let snapshot {
            return .data(snapshot, isStale: error != nil)
        }
        if let error {
            return .error(error)
        }
        return .loading
    }
}
