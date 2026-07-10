import XCTest
@testable import Codex_Usage

final class CodexRPCClientTests: XCTestCase {
    func testParsesRateLimitsResponse() throws {
        let json = """
        {
          "jsonrpc": "2.0",
          "id": 1,
          "result": {
            "rate_limits": {
              "primary": {
                "used_percent": 20.0,
                "window_duration_mins": 300,
                "resets_at": 1752158400
              },
              "secondary": {
                "used_percent": 50.0,
                "window_duration_mins": 10080,
                "resets_at": 1752441600
              }
            }
          }
        }
        """.data(using: .utf8)!
        
        let client = CodexRPCClient()
        let snapshot = try client.parseRateLimitsResponse(json)
        
        XCTAssertEqual(snapshot.primary.remainingPercent, 80.0, accuracy: 0.001)
        XCTAssertEqual(snapshot.secondary.remainingPercent, 50.0, accuracy: 0.001)
        let primaryResetsAt = try XCTUnwrap(snapshot.primary.resetsAt)
        XCTAssertEqual(primaryResetsAt.timeIntervalSince1970, 1752158400, accuracy: 0.001)
    }
}
