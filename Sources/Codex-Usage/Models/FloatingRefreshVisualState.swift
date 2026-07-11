enum FloatingRefreshVisualState: Equatable, Sendable {
    case logo
    case refresh
    case loading

    static func resolve(
        isLoading: Bool,
        isHovering: Bool
    ) -> FloatingRefreshVisualState {
        if isLoading { return .loading }
        if isHovering { return .refresh }
        return .logo
    }
}
