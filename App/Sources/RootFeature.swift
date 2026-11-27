import ComposableArchitecture
import Splash
import FocusTimer
import SessionLog
import Setting
import Domain


@Reducer
struct RootFeature {

    /// 기록 탭 NavigationStack에 쌓이는 화면.
    /// SessionLog와 Setting을 모두 아는 곳은 App뿐이라 여기서 정의한다.
    @Reducer
    enum LogPath {
        case setting(SettingFeature)
    }

    enum Tab: Equatable {
        case timer
        case log
    }

    @ObservableState
    struct State: Equatable {
        var selectedTab = Tab.timer
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
        /// 지금 로그인된 계정. 아직 불러오지 못했으면 nil이다.
        /// 설정 화면이 같은 참조를 받아, 여기서 바꾸면 그 화면에도 반영된다.
        @Shared var profile: Profile?

        init() {
            _profile = Shared(value: nil)
        }

        /// 스플래시를 보여 줄지. 연출과 첫 로그인 확인이 모두 끝나야 메인으로 넘어간다.
        /// 메인 화면의 요청이 토큰 없이 나가지 않게 로그인 확인을 기다린다.
        var isLaunching: Bool {
            !isSplashFinished || !isSignInChecked
        }
    }

    enum Action {
        case view(ViewAction)
        case effect(EffectAction)
        case splash(SplashFeature.Action)
        case timer(FocusHomeFeature.Action)
        case log(SessionLogHomeFeature.Action)
        case logPath(StackActionOf<LogPath>)

        /// 사용자와 시스템이 화면에 한 일.
        @CasePathable
        enum ViewAction {
            case onAppear
            case tabSelected(Tab)
            /// 앱이 다시 활성 상태가 됐다.
            case sceneActivated
        }

        /// UseCase 응답.
        @CasePathable
        enum EffectAction {
            case fetchProfileResponse(Result<Profile, DomainError>)
        }
    }

    @Dependency(\.ensureSignedInUseCase) var ensureSignedInUseCase
    @Dependency(\.fetchProfileUseCase) var fetchProfileUseCase

    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) { SplashFeature() }
        Scope(state: \.timer, action: \.timer) { FocusHomeFeature() }
        Scope(state: \.log, action: \.log) { SessionLogHomeFeature() }

        Reduce { state, action in
            switch action {
            case .view(let action):
                return viewAction(&state, action)

            case .effect(let action):
                return effectAction(&state, action)

            case .splash(.delegate(.finished)):
                state.isSplashFinished = true
                return .none

            case .log(.delegate(.settingTapped)):
                state.logPath.append(.setting(SettingFeature.State(profile: state.$profile)))
                return .none

            case .logPath(.element(id: _, action: .setting(.delegate(.accountChanged)))):
                return fetchProfile()

            case .logPath(.element(id: _, action: .setting(.delegate(.logout)))):
                state.resetForLogout()
                // 토큰이 지워졌으니 익명 계정을 다시 받는다.
                return ensureSignedIn()

            case .splash, .timer, .log, .logPath:
                return .none
            }
        }
        .forEach(\.logPath, action: \.logPath)
    }

    // MARK: - View

    private func viewAction(_ state: inout State, _ action: Action.ViewAction) -> Effect<Action> {
        switch action {
        case .onAppear:
            return ensureSignedIn()

        case .sceneActivated:
            guard state.needsSignInRetry else { return .none }
            state.needsSignInRetry = false
            return ensureSignedIn()

        case let .tabSelected(tab):
            state.selectedTab = tab
            return .none
        }
    }

    // MARK: - Effect

    private func effectAction(_ state: inout State, _ action: Action.EffectAction) -> Effect<Action> {
        switch action {
        case let .fetchProfileResponse(result):
            // 실패해도 메인으로 넘긴다. 타이머는 서버 없이도 쓸 수 있다.
            state.isSignInChecked = true
            switch result {
            case let .success(profile):
                state.$profile.withLock { $0 = profile }
            case .failure:
                state.needsSignInRetry = true
            }
            return .none
        }
    }

    /// 로그인을 확인하고 이어서 프로필을 불러온다. 어느 쪽이 실패해도 그 에러를 그대로 전한다.
    private func ensureSignedIn() -> Effect<Action> {
        .run { send in
            switch await ensureSignedInUseCase.execute() {
            case .success:
                await send(.effect(.fetchProfileResponse(fetchProfileUseCase.execute())))
            case let .failure(error):
                await send(.effect(.fetchProfileResponse(.failure(error))))
            }
        }
    }

    private func fetchProfile() -> Effect<Action> {
        .run { send in
            await send(.effect(.fetchProfileResponse(fetchProfileUseCase.execute())))
        }
    }
}

extension RootFeature.LogPath.State: Equatable {}

private extension RootFeature.State {
    /// 로그아웃하면 계정을 비우고 기록 스택을 닫은 뒤 타이머 탭으로 돌아간다.
    mutating func resetForLogout() {
        $profile.withLock { $0 = nil }
        logPath.removeAll()
        selectedTab = .timer
    }
}
