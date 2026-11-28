import ComposableArchitecture
import Splash
import FocusTimer
import SessionLog
import Setting
import Domain
import Foundation


@Reducer
struct RootFeature {

    /// 기록 탭 NavigationStack에 쌓이는 화면.
    /// SessionLog와 Setting을 모두 아는 곳은 App뿐이라 여기서 정의한다.
    @Reducer
    enum LogPath {
        case setting(SettingFeature)
    }

    /// 업데이트 알림 버튼이 보내는 액션.
    enum Alert: Equatable {
        case updateTapped
        case laterTapped
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
        /// 업데이트 확인이 끝났다. 확인에 실패했거나 권장 업데이트를 미룬 경우도 포함한다.
        /// 강제 업데이트면 끝나지 않아 메인으로 넘어가지 않는다.
        var isUpdateChecked = false
        /// 서버가 권하거나 요구한 업데이트. 스플래시가 끝나면 알림으로 띄운다.
        var pendingUpdate: AppUpdate?
        @Presents var alert: AlertState<Alert>?
        /// 지금 로그인된 계정. 아직 불러오지 못했으면 nil이다.
        /// 설정 화면이 같은 참조를 받아, 여기서 바꾸면 그 화면에도 반영된다.
        @Shared var profile: Profile?

        init() {
            _profile = Shared(value: nil)
        }

        /// 스플래시를 보여 줄지. 연출, 첫 로그인 확인, 업데이트 확인이 모두 끝나야 메인으로 넘어간다.
        /// 메인 화면의 요청이 토큰 없이 나가지 않게 로그인 확인을 기다린다.
        var isLaunching: Bool {
            !isSplashFinished || !isSignInChecked || !isUpdateChecked
        }
    }

    enum Action {
        case view(ViewAction)
        case effect(EffectAction)
        case splash(SplashFeature.Action)
        case timer(FocusHomeFeature.Action)
        case log(SessionLogHomeFeature.Action)
        case logPath(StackActionOf<LogPath>)
        case alert(PresentationAction<Alert>)

        /// 사용자와 시스템이 화면에 한 일.
        @CasePathable
        enum ViewAction {
            case onAppear
            /// 화면이 살아 있는 동안 이어지는 일(세션 만료 구독)과 업데이트 확인을 시작한다.
            case task
            case tabSelected(Tab)
            /// 앱이 다시 활성 상태가 됐다.
            case sceneActivated
        }

        /// UseCase 응답.
        @CasePathable
        enum EffectAction {
            case fetchProfileResponse(Result<Profile, DomainError>)
            case checkAppUpdateResponse(Result<AppUpdate, DomainError>)
            /// refresh token이 거절돼 토큰이 지워졌다.
            case sessionExpired
        }
    }

    @Dependency(\.ensureSignedInUseCase) var ensureSignedInUseCase
    @Dependency(\.fetchProfileUseCase) var fetchProfileUseCase
    @Dependency(\.observeSessionExpiredUseCase) var observeSessionExpiredUseCase
    @Dependency(\.checkAppUpdateUseCase) var checkAppUpdateUseCase
    @Dependency(\.openURL) var openURL

    /// 서버가 스토어 주소를 주지 않았을 때 여는 App Store 페이지. 환경과 상관없이 같다.
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6756012439")!

    enum CancelID {
        case signIn
    }

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
                state.presentUpdateAlertIfNeeded()
                return .none

            case .alert(.presented(.updateTapped)):
                guard let update = state.pendingUpdate else { return .none }
                if update.policy == .required {
                    // 업데이트하기 전에는 들어갈 수 없다. 스토어에서 그냥 돌아와도 알림이 다시 보인다.
                    state.alert = .requiredUpdate
                } else {
                    state.isUpdateChecked = true
                }
                return .run { _ in
                    await openURL(update.storeURL ?? Self.appStoreURL)
                }

            case .alert(.presented(.laterTapped)):
                state.isUpdateChecked = true
                return .none

            case .log(.delegate(.settingTapped)):
                state.logPath.append(.setting(SettingFeature.State(profile: state.$profile)))
                return .none

            case .log(.delegate(.startFocusTapped)):
                state.selectedTab = .timer
                return .none

            case let .logPath(.element(id: _, action: .setting(.delegate(.accountChanged(profile))))):
                // 설정 화면이 새 프로필을 받아 왔으면 그대로 쓰고, 받지 못했으면 여기서 다시 불러온다.
                guard let profile else { return fetchProfile() }
                state.$profile.withLock { $0 = profile }
                return .send(.log(.prefetch))

            case .logPath(.element(id: _, action: .setting(.delegate(.logout)))):
                state.resetForLogout()
                // 토큰이 지워졌으니 익명 계정을 다시 받는다.
                return ensureSignedIn()

            case .splash, .timer, .log, .logPath, .alert:
                return .none
            }
        }
        .forEach(\.logPath, action: \.logPath)
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - View

    private func viewAction(_ state: inout State, _ action: Action.ViewAction) -> Effect<Action> {
        switch action {
        case .onAppear:
            return ensureSignedIn()

        case .task:
            return .merge(
                observeSessionExpired(),
                checkAppUpdate()
            )

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
                // 기록 탭을 처음 열 때 빈 화면이 보이지 않게 미리 받아 둔다.
                return .send(.log(.prefetch))
            case .failure:
                state.needsSignInRetry = true
                return .none
            }

        case let .checkAppUpdateResponse(result):
            switch result {
            case let .success(update) where update.policy != .upToDate:
                state.pendingUpdate = update
                state.presentUpdateAlertIfNeeded()
            case .success, .failure:
                // 확인에 실패하면 막지 않는다. 강제 업데이트인지는 서버가 답했을 때만 알 수 있고,
                // 스플래시에 가둬 두면 오프라인으로 처음 연 사용자는 로고만 보다 떠난다.
                state.isUpdateChecked = true
            }
            return .none

        case .sessionExpired:
            // 로그아웃과 같은 흐름이다. 보던 계정 화면을 닫고 익명 계정으로 다시 시작한다.
            state.resetForLogout()
            return ensureSignedIn()
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
        // 로그아웃과 세션 만료가 겹쳐도 익명 로그인은 한 번만 보낸다.
        .cancellable(id: CancelID.signIn, cancelInFlight: true)
    }

    private func checkAppUpdate() -> Effect<Action> {
        .run { send in
            await send(.effect(.checkAppUpdateResponse(checkAppUpdateUseCase.execute())))
        }
    }

    /// 앱이 살아 있는 동안 세션 만료를 받는다. 뷰의 `.task`가 끝나면 함께 끝난다.
    private func observeSessionExpired() -> Effect<Action> {
        .run { send in
            for await _ in observeSessionExpiredUseCase.execute() {
                await send(.effect(.sessionExpired))
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
    /// 스플래시 연출이 끝난 뒤에 띄운다. 연출 도중에 알림이 덮지 않게 한다.
    mutating func presentUpdateAlertIfNeeded() {
        guard isSplashFinished, !isUpdateChecked, alert == nil, let pendingUpdate else { return }
        alert = pendingUpdate.policy == .required ? .requiredUpdate : .optionalUpdate
    }

    /// 로그아웃하면 계정을 비우고 기록 스택을 닫은 뒤 타이머 탭으로 돌아간다.
    mutating func resetForLogout() {
        $profile.withLock { $0 = nil }
        // 이전 계정의 기록이 남아 보이지 않게 비운다.
        log = SessionLogHomeFeature.State()
        logPath.removeAll()
        selectedTab = .timer
    }
}
