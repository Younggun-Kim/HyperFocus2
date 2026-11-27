import ComposableArchitecture
import Domain
import Foundation
import Testing
@testable import SessionLog

@MainActor
struct SessionLogHomeFeatureTests {
    /// 2026-02-06(금) 01:00 UTC
    private static let now = Date(timeIntervalSince1970: 1_770_339_600)
    private static let utc = TimeZone(identifier: "UTC")!

    private func makeStore(
        initialState: SessionLogHomeFeature.State = .init(),
        fetch: @escaping @Sendable () async -> Result<SessionLogDashboard, DomainError>
    ) -> TestStoreOf<SessionLogHomeFeature> {
        TestStore(initialState: initialState) {
            SessionLogHomeFeature()
        } withDependencies: {
            $0.fetchSessionLogDashboardUseCase.execute = fetch
            $0.date.now = Self.now
            $0.timeZone = Self.utc
        }
    }

    @Test func 화면이_보이면_요약을_불러와_그래프와_타임라인을_만든다() async {
        let dashboard = SessionLogDashboard(
            isEmpty: false,
            todayFocusText: "25m",
            week: [
                DailyFocus(day: "2026-02-02", focusMinutes: 50),
                DailyFocus(day: "2026-02-03", focusMinutes: 0),
                DailyFocus(day: "2026-02-04", focusMinutes: 100),
                DailyFocus(day: "2026-02-05", focusMinutes: 0),
                DailyFocus(day: "2026-02-06", focusMinutes: 25),
            ],
            timeline: [
                TimelineEntry(
                    kind: .focus,
                    name: "Reading",
                    startedAt: Self.now,
                    endedAt: Self.now.addingTimeInterval(1500),
                    durationSeconds: 1500,
                    durationMinutes: 25,
                    isNew: true
                ),
            ]
        )
        let store = makeStore { .success(dashboard) }

        await store.send(.view(.task)) {
            $0.chart = WeeklyChart(week: [], today: Self.now, timeZone: Self.utc)
        }
        await store.receive(\.effect.dashboardResponse.success) {
            $0.dashboard = dashboard
            $0.chart = WeeklyChart(week: dashboard.week, today: Self.now, timeZone: Self.utc)
            $0.timeline = [
                TimelineRow(
                    id: dashboard.timeline[0].id,
                    content: .session(time: "01:00 - 01:25 (25m)", title: "Reading", isNew: true)
                ),
            ]
        }
        #expect(store.state.isEmpty == false)
        #expect(store.state.chart.bars.map(\.isToday) == [false, false, false, false, true, false, false])
        #expect(store.state.chart.bars.map(\.heightRatio) == [0.5, 0, 1, 0, 0.25, 0, 0])
    }

    @Test func 받기_전에는_빈_화면이고_오늘_칸만_표시한다() async {
        let store = makeStore { .success(SessionLogDashboard(isEmpty: true)) }
        #expect(store.state.isEmpty)

        await store.send(.view(.task)) {
            $0.chart = WeeklyChart(week: [], today: Self.now, timeZone: Self.utc)
        }
        // 금요일은 월요일부터 다섯 번째 칸이다.
        #expect(store.state.chart.bars.firstIndex(where: \.isToday) == 4)

        await store.receive(\.effect.dashboardResponse.success) {
            $0.dashboard = SessionLogDashboard(isEmpty: true)
        }
        #expect(store.state.isEmpty)
    }

    @Test func 불러오기에_실패하면_앞서_받은_요약을_두고_토스트로_알린다() async {
        var state = SessionLogHomeFeature.State()
        state.dashboard = SessionLogDashboard(isEmpty: false, todayFocusText: "25m")
        let store = makeStore(initialState: state) { .failure(.offline) }

        await store.send(.view(.task))
        await store.receive(\.effect.dashboardResponse.failure) {
            $0.toast = "Please check your internet connection."
        }

        await store.send(.view(.toastDismissed)) {
            $0.toast = nil
        }
    }

    @Test func 취소는_알리지_않는다() async {
        var state = SessionLogHomeFeature.State()
        state.dashboard = SessionLogDashboard(isEmpty: true)
        let store = makeStore(initialState: state) { .failure(.cancelled) }

        await store.send(.view(.task))
        await store.receive(\.effect.dashboardResponse.failure)
    }

    @Test func 설정_버튼을_누르면_settingTapped_delegate를_보낸다() async {
        let store = makeStore { .failure(.unknown) }

        await store.send(.view(.settingTapped))
        await store.receive(\.delegate.settingTapped)
    }

    @Test func 시작을_누르면_startFocusTapped_delegate를_보낸다() async {
        let store = makeStore { .failure(.unknown) }

        await store.send(.view(.startTapped))
        await store.receive(\.delegate.startFocusTapped)
    }
}
