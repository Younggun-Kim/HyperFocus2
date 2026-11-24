import ComposableArchitecture
import FocusTimer
import SessionLog
import Setting


@Reducer
struct RootFeature {
    /// 기록 탭 NavigationStack에 쌓이는 화면.
    /// SessionLog와 Setting을 모두 아는 곳은 App뿐이라 여기서 정의한다.
    @Reducer
    enum LogPath {
        case setting(SettingFeature)
    }

    @ObservableState
    struct State: Equatable {
        var timer = FocusHomeFeature.State()
        var log = SessionLogHomeFeature.State()
        var logPath = StackState<LogPath.State>()
    }

    enum Action: Equatable {
        case timer(FocusHomeFeature.Action)
        case log(SessionLogHomeFeature.Action)
        case logPath(StackActionOf<LogPath>)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.timer, action: \.timer) { FocusHomeFeature() }
        Scope(state: \.log, action: \.log) { SessionLogHomeFeature() }

        Reduce { state, action in
            switch action {
            case .log(.delegate(.settingTapped)):
                state.logPath.append(.setting(SettingFeature.State()))
                return .none

            case .timer, .log, .logPath:
                return .none
            }
        }
        .forEach(\.logPath, action: \.logPath)
    }
}

extension RootFeature.LogPath.State: Equatable {}
extension RootFeature.LogPath.Action: Equatable {}
