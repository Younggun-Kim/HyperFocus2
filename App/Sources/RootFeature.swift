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
        
        /// 스플래시 연출이 끝났다.
        var isSplashFinished = false
        /// 첫 로그인 확인이 끝났다. 실패로 끝난 경우도 포함한다.
        var isSignInChecked = false
        /// 로그인 확인에 실패했다. 앱이 다시 활성화되면 한 번 더 시도한다.
        var needsSignInRetry = false
        
        /// 스플래시를 보여 줄지. 연출과 첫 로그인 확인이 모두 끝나야 메인으로 넘어간다.
        /// 메인 화면의 요청이 토큰 없이 나가지 않게 로그인 확인을 기다린다.
        var isLaunching: Bool {
            !isSplashFinished || !isSignInChecked
        }
    }
    
    enum Action {
        case splash(SplashFeature.Action)
        case timer(FocusHomeFeature.Action)
        case log(SessionLogHomeFeature.Action)
        case logPath(StackActionOf<LogPath>)
        
        case onAppear
        /// 앱이 다시 활성 상태가 됐다.
        case sceneActivated
        case effect(EffectAction)
        
        @CasePathable
        enum EffectAction {
            case ensureSignedInResponse(Result<Void, DomainError>)
        }
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) { SplashFeature() }
        Scope(state: \.timer, action: \.timer) { FocusHomeFeature() }
        Scope(state: \.log, action: \.log) { SessionLogHomeFeature() }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return ensureSignedIn()
                
            case .sceneActivated:
                guard state.needsSignInRetry else { return .none }
                state.needsSignInRetry = false
                return ensureSignedIn()
                
            case .splash(.delegate(.finished)):
                state.isSplashFinished = true
                return .none
                
            case .log(.delegate(.settingTapped)):
                state.logPath.append(.setting(SettingFeature.State()))
                return .none
                
            case .splash, .timer, .log, .logPath:
                return .none
                
            case .effect(let effect):
                return effectAction(&state, effect)
            }
        }
        .forEach(\.logPath, action: \.logPath)
    }
    
    func effectAction(_ state: inout State, _ action: Action.EffectAction) -> Effect<Action> {
        switch action {
        case .ensureSignedInResponse(let result):
            // 실패해도 메인으로 넘긴다. 타이머는 서버 없이도 쓸 수 있다.
            state.isSignInChecked = true
            if case .failure = result {
                state.needsSignInRetry = true
            }
            return .none
        }
    }
    
    private func ensureSignedIn() -> Effect<Action> {
        .run { send in
            await send(.effect(.ensureSignedInResponse(ensureSignedInUseCase.execute())))
        }
    }
}

extension RootFeature.LogPath.State: Equatable {}
extension RootFeature.LogPath.Action: Equatable {}
