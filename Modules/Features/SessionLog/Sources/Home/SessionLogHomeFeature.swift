//
//  SessionLogHomeFeature.swift
//  SessionLog
//
//  Created by 김영건 on 11/24/26.
//

import BaseFeature
import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct SessionLogHomeFeature {
    @ObservableState
    public struct State: Equatable {
        /// 서버에서 받은 요약. 아직 받지 못했으면 nil이다.
        var dashboard: SessionLogDashboard?
        var chart = WeeklyChart.placeholder
        var timeline: [TimelineRow] = []
        /// 화면 아래에 잠깐 띄우는 안내. 뷰가 시간이 지나면 `toastDismissed`로 지운다.
        var toast: String?

        /// 기록이 없다. 받기 전에도 빈 화면을 보여 준다.
        var isEmpty: Bool {
            dashboard?.isEmpty ?? true
        }

        public init() {}
    }

    public enum Action {
        case view(ViewAction)
        case effect(EffectAction)
        case delegate(Delegate)

        /// 사용자가 화면에서 한 일.
        @CasePathable
        public enum ViewAction {
            /// 화면이 보일 때마다 온다. 탭을 다시 누르거나 설정에서 돌아와도 온다.
            case task
            case settingTapped
            case startTapped
            case toastDismissed
        }

        /// UseCase 응답.
        @CasePathable
        public enum EffectAction {
            case dashboardResponse(Result<SessionLogDashboard, DomainError>)
        }

        @CasePathable
        public enum Delegate: Equatable {
            case settingTapped
            /// 빈 화면에서 시작을 눌렀다. 타이머로 옮기는 것은 부모가 한다.
            case startFocusTapped
        }
    }

    @Dependency(\.fetchSessionLogDashboardUseCase) var fetchSessionLogDashboardUseCase
    @Dependency(\.date.now) var now
    @Dependency(\.timeZone) var timeZone

    enum CancelID {
        case fetchDashboard
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(let action):
                return viewAction(&state, action)

            case .effect(let action):
                return effectAction(&state, action)

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - View

    private func viewAction(_ state: inout State, _ action: Action.ViewAction) -> Effect<Action> {
        switch action {
        case .task:
            if state.dashboard == nil {
                // 받기 전에도 오늘 칸을 표시한다.
                state.chart = WeeklyChart(week: [], today: now, timeZone: timeZone)
            }
            return fetchDashboard()

        case .settingTapped:
            return .send(.delegate(.settingTapped))

        case .startTapped:
            return .send(.delegate(.startFocusTapped))

        case .toastDismissed:
            state.toast = nil
            return .none
        }
    }

    // MARK: - Effect

    private func effectAction(_ state: inout State, _ action: Action.EffectAction) -> Effect<Action> {
        switch action {
        case let .dashboardResponse(.success(dashboard)):
            state.dashboard = dashboard
            state.chart = WeeklyChart(week: dashboard.week, today: now, timeZone: timeZone)
            state.timeline = TimelineRow.rows(from: dashboard.timeline, timeZone: timeZone)
            return .none

        case let .dashboardResponse(.failure(error)):
            // 앞서 받은 요약은 그대로 둔다.
            state.toast = error.failureMessage
            return .none
        }
    }

    /// 화면이 사라져 취소되면 `send`가 액션을 버린다.
    private func fetchDashboard() -> Effect<Action> {
        .run { send in
            await send(.effect(.dashboardResponse(fetchSessionLogDashboardUseCase.execute())))
        }
        .cancellable(id: CancelID.fetchDashboard, cancelInFlight: true)
    }
}
