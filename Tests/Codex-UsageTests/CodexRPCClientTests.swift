import XCTest
@testable import Codex_Usage

final class CodexRPCClientTests: XCTestCase {
    private let client = CodexRPCClient()

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

        let snapshot = try client.parseRateLimitsResponse(json)

        XCTAssertEqual(snapshot.primary.remainingPercent, 80.0, accuracy: 0.001)
        XCTAssertEqual(snapshot.secondary.remainingPercent, 50.0, accuracy: 0.001)
        let primaryResetsAt = try XCTUnwrap(snapshot.primary.resetsAt)
        XCTAssertEqual(primaryResetsAt.timeIntervalSince1970, 1752158400, accuracy: 0.001)
    }

    func testThrowsRPCFailedWhenResponseContainsError() {
        let json = """
        {
          "jsonrpc": "2.0",
          "id": 1,
          "error": {
            "code": -32600,
            "message": "Invalid Request"
          }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try client.parseRateLimitsResponse(json)) { error in
            XCTAssertEqual(error as? UsageError, UsageError.rpcFailed("Invalid Request"))
        }
    }

    func testThrowsRPCFailedWhenResultIsMissing() {
        let json = """
        {
          "jsonrpc": "2.0",
          "id": 1
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try client.parseRateLimitsResponse(json)) { error in
            XCTAssertEqual(error as? UsageError, UsageError.rpcFailed("Missing result"))
        }
    }

    func testThrowsDecodeFailedForMalformedJSON() {
        let json = "{ not valid json ".data(using: .utf8)!

        XCTAssertThrowsError(try client.parseRateLimitsResponse(json)) { error in
            guard let usageError = error as? UsageError,
                  case .decodeFailed = usageError else {
                XCTFail("Expected decodeFailed, got \(error)")
                return
            }
        }
    }

    func testThrowsDecodeFailedForMissingRequiredFields() {
        let json = """
        {
          "jsonrpc": "2.0",
          "id": 1,
          "result": {
            "rate_limits": {
              "primary": {
                "window_duration_mins": 300
              }
            }
          }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try client.parseRateLimitsResponse(json)) { error in
            guard let usageError = error as? UsageError,
                  case .decodeFailed = usageError else {
                XCTFail("Expected decodeFailed, got \(error)")
                return
            }
        }
    }

    func testParsesCurrentCamelCaseResponseWithUnknownFields() throws {
        let json = """
        {
          "id": 1,
          "result": {
            "rateLimits": {
              "limitId": "codex",
              "planType": "plus",
              "primary": {
                "usedPercent": 12,
                "windowDurationMins": 300,
                "resetsAt": 1752158400,
                "futureField": true
              },
              "secondary": {
                "usedPercent": 34,
                "windowDurationMins": 10080,
                "resetsAt": 1752441600
              }
            },
            "futureTopLevelField": { "enabled": true }
          }
        }
        """.data(using: .utf8)!

        let snapshot = try client.parseRateLimitsResponse(json)

        XCTAssertEqual(snapshot.primary.usedPercent, 12)
        XCTAssertEqual(snapshot.secondary.usedPercent, 34)
    }

    func testFallsBackToCodexMultiBucketResponse() throws {
        let json = """
        {
          "id": 1,
          "result": {
            "rateLimitsByLimitId": {
              "other": {
                "primary": { "usedPercent": 90 }
              },
              "codex": {
                "primary": {
                  "usedPercent": 21,
                  "windowDurationMins": 300,
                  "resetsAt": 1752158400
                },
                "secondary": {
                  "usedPercent": 43,
                  "windowDurationMins": 10080,
                  "resetsAt": 1752441600
                }
              }
            }
          }
        }
        """.data(using: .utf8)!

        let snapshot = try client.parseRateLimitsResponse(json)

        XCTAssertEqual(snapshot.primary.usedPercent, 21)
        XCTAssertEqual(snapshot.secondary.usedPercent, 43)
    }

    func testFallsBackToFirstCompleteMultiBucketResponse() throws {
        let json = """
        {
          "id": 1,
          "result": {
            "rateLimitsByLimitId": {
              "incomplete": {
                "primary": { "usedPercent": 90 }
              },
              "workspace": {
                "primary": { "usedPercent": 31 },
                "secondary": { "usedPercent": 52 }
              }
            }
          }
        }
        """.data(using: .utf8)!

        let snapshot = try client.parseRateLimitsResponse(json)

        XCTAssertEqual(snapshot.primary.usedPercent, 31)
        XCTAssertEqual(snapshot.secondary.usedPercent, 52)
    }

    func testRejectsIncompleteRateLimitWindowsInsteadOfShowingFullRemainingQuota() {
        let json = """
        {
          "id": 1,
          "result": {
            "rateLimits": {
              "primary": { "usedPercent": 20 }
            }
          }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try client.parseRateLimitsResponse(json))
    }

    // MARK: - extractResponseLine

    func testExtractResponseLineFindsMatchingId() throws {
        let output = """
        {"jsonrpc":"2.0","id":0,"result":{"protocolVersion":"2024-11-05","serverInfo":{"name":"codex","version":"1.0.0"}}}
        {"jsonrpc":"2.0","id":1,"result":{"rate_limits":{"primary":{"used_percent":10.0,"window_duration_mins":300,"resets_at":1752158400},"secondary":{"used_percent":30.0,"window_duration_mins":10080,"resets_at":1752441600}}}}
        """.data(using: .utf8)!

        let line = client.extractResponseLine(for: 1, from: output)
        let unwrappedLine = try XCTUnwrap(line)
        XCTAssertTrue(String(data: unwrappedLine, encoding: .utf8)!.contains("rate_limits"))
    }

    func testExtractResponseLineReturnsNilForMissingId() {
        let output = """
        {"jsonrpc":"2.0","id":0,"result":{"protocolVersion":"2024-11-05"}}
        {"jsonrpc":"2.0","method":"notifications/progress"}
        """.data(using: .utf8)!

        let line = client.extractResponseLine(for: 99, from: output)
        XCTAssertNil(line)
    }
}
