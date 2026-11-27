import Dependencies
import Domain
import Testing

/// UseCase는 지금 Repository에 위임만 한다. 위임이 끊기지 않았는지 확인한다.
struct FetchSessionLogDashboardUseCaseTests {
    @Test func 저장소의_요약을_돌려준다() async throws {
        let stored = SessionLogDashboard(
            isEmpty: false,
            todayFocusText: "1h 30m",
            week: [DailyFocus(day: "2026-02-02", focusMinutes: 90)]
        )

        let dashboard = try await withDependencies {
            $0.sessionLogRepository.fetchDashboard = { .success(stored) }
        } operation: {
            try await FetchSessionLogDashboardUseCase.liveValue.execute().get()
        }

        #expect(dashboard == stored)
    }

    @Test func 저장소의_Domain_에러를_그대로_돌려준다() async {
        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.sessionLogRepository.fetchDashboard = { .failure(.offline) }
            } operation: {
                try await FetchSessionLogDashboardUseCase.liveValue.execute().get()
            }
        }
    }
}
