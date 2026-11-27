import CoreNetwork
import Domain
import Foundation
import Testing
@testable import Data

struct SessionLogRepositoryTests {
    private let dashboardJSON = #"""
    {
      "success": true,
      "data": {
        "isEmpty": false,
        "todayFocusSeconds": 5400,
        "todayFocusDisplay": "1h 30m",
        "diffMessage": "30m more than yesterday",
        "weekTotalDisplay": "4h 10m",
        "weeklyData": [
          {"date": "2026-02-02", "dayOfWeekShort": "M", "focusMinutes": 160},
          {"date": "2026-02-03", "dayOfWeekShort": "T"}
        ],
        "timeline": [
          {"type": "FOCUS", "sessionId": "session-1", "name": "Reading", "startedAt": "2026-02-03T01:00:00Z", "endedAt": "2026-02-03T01:25:00Z", "durationSeconds": 1500, "durationMinutes": 25, "isNew": true},
          {"type": "GAP", "startedAt": "2026-02-03T01:25:00Z", "endedAt": "2026-02-03T01:40:00Z", "durationSeconds": 900, "durationMinutes": 15},
          {"type": "NAP", "startedAt": "2026-02-03T01:40:00Z", "endedAt": "2026-02-03T01:50:00Z", "durationSeconds": 600, "durationMinutes": 10}
        ]
      }
    }
    """#

    @Test func 요약을_조회하면_응답을_Entity로_바꾼다() async throws {
        let service = FakeAPIService(.json(dashboardJSON))
        let repository = SessionLogRepository.live(service: service)

        let dashboard = try await repository.fetchDashboard().get()

        let start = Date(timeIntervalSince1970: 1_770_080_400) // 2026-02-03T01:00:00Z
        #expect(dashboard == SessionLogDashboard(
            isEmpty: false,
            todayFocusText: "1h 30m",
            comparisonText: "30m more than yesterday",
            weekTotalText: "4h 10m",
            week: [
                DailyFocus(day: "2026-02-02", focusMinutes: 160),
                DailyFocus(day: "2026-02-03", focusMinutes: 0),
            ],
            // 모르는 종류(NAP)는 빠진다.
            timeline: [
                TimelineEntry(
                    kind: .focus,
                    name: "Reading",
                    startedAt: start,
                    endedAt: start.addingTimeInterval(1500),
                    durationSeconds: 1500,
                    durationMinutes: 25,
                    isNew: true
                ),
                TimelineEntry(
                    kind: .gap,
                    startedAt: start.addingTimeInterval(1500),
                    endedAt: start.addingTimeInterval(2400),
                    durationSeconds: 900,
                    durationMinutes: 15
                ),
            ]
        ))
        let endpoint = try #require(service.endpoints.first as? SessionLogAPI.FetchDashboard)
        #expect(endpoint.method == .get)
        #expect(endpoint.requiresAuth)
    }

    @Test func 기록이_없으면_빈_요약을_돌려준다() async throws {
        let repository = SessionLogRepository.live(
            service: FakeAPIService(.json(#"{"success": true, "data": {"isEmpty": true}}"#))
        )

        let dashboard = try await repository.fetchDashboard().get()

        #expect(dashboard == SessionLogDashboard(isEmpty: true))
    }

    @Test func 통신_에러는_Domain_에러로_바꿔_돌려준다() async {
        let repository = SessionLogRepository.live(service: FakeAPIService(.failure(APIError.networkError("offline"))))

        await #expect(throws: DomainError.offline) {
            try await repository.fetchDashboard().get()
        }
    }

    @Test func 요청이_취소되면_cancelled를_돌려준다() async {
        let repository = SessionLogRepository.live(service: FakeAPIService(.failure(APIError.cancelled)))

        await #expect(throws: DomainError.cancelled) {
            try await repository.fetchDashboard().get()
        }
    }
}
