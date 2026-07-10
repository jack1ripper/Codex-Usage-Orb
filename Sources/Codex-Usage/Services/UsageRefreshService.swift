import Foundation
import Combine

@MainActor
final class UsageRefreshService: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var error: UsageError?
    @Published private(set) var isLoading: Bool = false
    
    private let rpcClient: CodexRPCClient
    private var timer: Timer?
    private let refreshInterval: TimeInterval
    
    init(rpcClient: CodexRPCClient = CodexRPCClient(), refreshInterval: TimeInterval = 60) {
        self.rpcClient = rpcClient
        self.refreshInterval = refreshInterval
    }
    
    func start() {
        Task {
            await refresh()
        }
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.refresh()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let newSnapshot = try await rpcClient.fetchUsage()
            snapshot = newSnapshot
            error = nil
        } catch let usageError as UsageError {
            error = usageError
        } catch {
            self.error = .rpcFailed(error.localizedDescription)
        }
        isLoading = false
    }
}
