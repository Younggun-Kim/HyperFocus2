import ComposableArchitecture
import FocusTimer
import SessionHistory

/// 자식 Feature를 조립하는 부모 Reducer.
/// Feature끼리는 서로 모르므로, 형제 간 소통은 여기서 delegate 액션을 받아 연결한다.
@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        var timer = FocusTimerFeature.State()
        var history = SessionHistoryFeature.State()
    }

    enum Action: Equatable {
        case timer(FocusTimerFeature.Action)
        case history(SessionHistoryFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.timer, action: \.timer) { FocusTimerFeature() }
        Scope(state: \.history, action: \.history) { SessionHistoryFeature() }
        Reduce { _, action in
            switch action {
            case .timer(.delegate(.sessionFinished)):
                return .send(.history(.reload))
            case .timer, .history:
                return .none
            }
        }
    }
}
