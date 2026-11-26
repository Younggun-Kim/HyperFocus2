import ComposableArchitecture
import Splash
import FocusTimer
import SessionLog
import Setting
import Domain


@Reducer
struct RootFeature {
    @Dependency(\.ensureSignedInUseCase) var ensureSignedInUseCase

    /// 기록 탭 NavigationStack에 쌓이는 화면.
    /// SessionLog와 Setting을 모두 아는 곳은 App뿐이라 여기서 정의한다.
    @Reducer
    enum LogPath {
        case setting(SettingFeature)
    }
    
    @ObservableState
    struct State: Equatable {
        var splash = SplashFeature.State()
        var timer = FocusHomeFeature.State()
        var log = SessionLogHomeFeature.State()
        var logPath = StackState<LogPath.State>()
    }
    
    enum Action: Equatable {
        case splash(SplashFeature.Action)
        case timer(FocusHomeFeature.Action)
        case log(SessionLogHomeFeature.Action)
        case logPath(StackActionOf<LogPath>)
        case onAppear

        
        enum Effect {
            
        }
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) { SplashFeature() }
        Scope(state: \.timer, action: \.timer) { FocusHomeFeature() }
        Scope(state: \.log, action: \.log) { SessionLogHomeFeature() }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                
                return .none
            case .splash(.delegate(.finished)):
                return .none
                
            case .log(.delegate(.settingTapped)):
                state.logPath.append(.setting(SettingFeature.State()))
                return .none
                
            case .splash, .timer, .log, .logPath:
                return .none
            }
        }
        .forEach(\.logPath, action: \.logPath)
    }
}

extension RootFeature.LogPath.State: Equatable {}
extension RootFeature.LogPath.Action: Equatable {}
