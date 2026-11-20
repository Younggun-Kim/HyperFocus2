import Foundation
import Testing
@testable import CoreNetwork

/// 1단계: 공통 디코더의 날짜 포맷
struct APIDecoderTests {
    @Test(arguments: [
        ("2026-11-20T07:50:11.123Z", 123_000_000),
        ("2026-11-20T16:50:11.123+09:00", 123_000_000),
        ("2026-11-20T07:50:11.123456", 123_456_000),
        ("2026-11-20T07:50:11.123", 123_000_000),
        ("2026-11-20T07:50:11", 0),
    ])
    func 지원하는_날짜_포맷을_UTC로_디코딩한다(string: String, nanosecond: Int) throws {
        let decoded = try decode(string)

        let expected = utcDate(nanosecond: nanosecond)
        #expect(abs(decoded.timeIntervalSince(expected)) < 0.000_001)
    }

    @Test func 지원하지_않는_날짜_포맷이면_실패한다() {
        #expect(throws: DecodingError.self) {
            try decode("2026/11/20 07:50:11")
        }
    }

    @Test func 디코더는_공유된다() {
        #expect(JSONDecoder.api === JSONDecoder.api)
    }
}

// MARK: - Helpers

private struct Event: Decodable {
    let createdAt: Date
}

private func decode(_ dateString: String) throws -> Date {
    let json = #"{"created_at": "\#(dateString)"}"#
    return try JSONDecoder.api.decode(Event.self, from: Data(json.utf8)).createdAt
}

/// 2026-11-20 07:50:11 UTC
private func utcDate(nanosecond: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar.date(from: DateComponents(
        year: 2026, month: 11, day: 20,
        hour: 7, minute: 50, second: 11,
        nanosecond: nanosecond
    ))!
}
