import ComposableArchitecture
import Domain
import Foundation
import os

@Reducer
public struct SettingFeature {

    /// 설정 화면에서 띄우는 시트.
    @Reducer
    public enum Destination {
        /// 개인정보처리방침, 이용약관. 로직이 없어 주소만 들고 있다.
        @ReducerCaseIgnored
        case webPage(URL)
        case feedback(FeedbackFeature)
        case alert(AlertState<Alert>)
    }

    /// 알림 버튼이 보내는 액션.
    public enum Alert: Equatable {
        /// 탈퇴 확인 알림에서 삭제를 눌렀다.
        case confirmWithdrawal
    }

    @ObservableState
    public struct State: Equatable {
        /// 화면에 보이는 값. 토글하면 바로 바뀌고, 기기에 저장된 값이 바뀌면 따라 바뀐다.
        var setting: AppSetting
        /// Apple 로그인 요청을 보내고 새 계정의 프로필을 받는 중. 버튼을 또 눌러도 한 번만 보낸다.
        /// 프로필까지 받아야 끝난다. 그 사이 계정 카드가 로그인 버튼으로 돌아가 보이지 않게 로딩을 보여 준다.
        var isSigningIn = false
        /// 지금 로그인된 계정. 소유자가 넘겨준 참조라 여기서는 읽기만 한다.
        /// 로그인 뒤 새 프로필은 `accountChanged`로 소유자에게 넘겨 바꾸게 한다.
        @Shared var profile: Profile?
        @Presents var destination: Destination.State?
        /// 화면 아래에 잠깐 띄우는 안내. 뷰가 시간이 지나면 `toastDismissed`로 지운다.
        var toast: String?

        /// Apple 계정으로 로그인했을 때만 값이 있다.
        var email: String? {
            guard let profile, profile.isAppleUser else { return nil }
            return profile.email
        }

        public init(setting: AppSetting = .default, profile: Shared<Profile?> = Shared(value: nil)) {
            self.setting = setting
            self._profile = profile
        }
    }

    public enum Action {
        case view(ViewAction)
        case effect(EffectAction)
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        /// 사용자가 화면에서 한 일.
        @CasePathable
        public enum ViewAction {
            /// 화면이 보이는 동안 저장된 설정을 구독한다.
            case task
            case deviceSettingChanged(type: SettingMenuType.DeviceSetting, isOn: Bool)
            case aboutUsTapped(SettingMenuType.AboutUs)
            case appleSignInCompleted(AppleSignInResult)
            case logoutTapped
            case withdrawalTapped
            case toastDismissed
        }

        /// UseCase 응답.
        @CasePathable
        public enum EffectAction {
            /// 기기에 저장된 설정이 바뀌었다. 구독을 시작할 때도 지금 값으로 한 번 온다.
            case settingChanged(AppSetting)
            case updateSettingResponse(Result<Void, DomainError>)
            case signInResponse(Result<Void, DomainError>)
            case fetchProfileResponse(Result<Profile, DomainError>)
            case withdrawResponse(Result<Void, DomainError>)
        }

        @CasePathable
        public enum Delegate: Equatable {
            /// 로그인된 계정이 바뀌었다. 새 프로필을 받지 못했으면 nil이라 소유자가 다시 불러온다.
            case accountChanged(Profile?)
            /// 로그아웃했다.(or 탈퇴)
            case logout
        }
    }

    enum CancelID {
        case signIn
        case fetchProfile
    }

    @Dependency(\.observeSettingUseCase) var observeSettingUseCase
    @Dependency(\.updateSettingUseCase) var updateSettingUseCase
    @Dependency(\.signInWithAppleUseCase) var signInWithAppleUseCase
    @Dependency(\.fetchProfileUseCase) var fetchProfileUseCase
    @Dependency(\.logoutUseCase) var logoutUseCase
    @Dependency(\.withdrawUseCase) var withdrawUseCase

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(let action):
                return viewAction(&state, action)

            case .effect(let action):
                return effectAction(&state, action)

            case .destination(.presented(.feedback(.delegate(.sent)))):
                state.destination = nil
                state.toast = "Message received! Thanks. 💌"
                return .none

            case .destination(.presented(.alert(.confirmWithdrawal))):
                return withdraw()

            case .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - View

    private func viewAction(_ state: inout State, _ action: Action.ViewAction) -> Effect<Action> {
        switch action {
        case .task:
            return observeSetting()

        case let .deviceSettingChanged(type, isOn):
            guard state.setting[type] != isOn else { return .none }
            state.setting[type] = isOn
            return updateSetting(state.setting)

        case let .aboutUsTapped(item):
            if let url = item.url {
                state.destination = .webPage(url)
            } else {
                state.destination = .feedback(FeedbackFeature.State())
            }
            return .none

        case let .appleSignInCompleted(result):
            switch result {
            case let .authorized(credential):
                return signIn(with: credential, state: &state)

            case .canceled:
                Logger.setting.debug("Apple 로그인: 사용자가 취소")
                return .none

            case let .failed(code):
                Logger.setting.error("Apple 로그인 실패: code \(code)")
                state.presentAlert(.appleSignInFailure(.unknown))
                return .none
            }

        case .logoutTapped:
            return logout()

        case .withdrawalTapped:
            state.presentAlert(.withdrawalConfirm)
            return .none

        case .toastDismissed:
            state.toast = nil
            return .none
        }
    }

    /// Apple 인증 결과를 서버 로그인 요청으로 바꿔 보낸다.
    private func signIn(with credential: AppleCredential, state: inout State) -> Effect<Action> {
        // 토큰, 사용자 식별자, email 값은 찍지 않는다. 있는지만 남긴다.
        Logger.setting.info(
            "Apple 인증 완료: identityToken \(credential.identityToken != nil), authorizationCode \(credential.authorizationCode != nil), email \(credential.email != nil)"
        )
        guard !state.isSigningIn else { return .none }
        guard let request = credential.signInRequest else {
            Logger.setting.error("Apple 로그인 실패: 서버에 보낼 토큰이나 코드가 없다")
            state.presentAlert(.appleSignInFailure(.unknown))
            return .none
        }
        state.isSigningIn = true
        return signIn(request)
    }

    // MARK: - Effect

    private func effectAction(_ state: inout State, _ action: Action.EffectAction) -> Effect<Action> {
        switch action {
        case let .settingChanged(setting):
            state.setting = setting
            return .none

        case let .updateSettingResponse(result):
            // 서버에 보내지 못한 것은 실패가 아니다(다음 동기화에서 보낸다). 기기에 쓰지 못했을 때만 온다.
            // 화면 값은 구독이 기기에 남은 값으로 맞춘다.
            if case let .failure(error) = result {
                state.presentAlert(.settingSaveFailure(error))
            }
            return .none

        case let .signInResponse(result):
            switch result {
            case .success:
                // 로그인 중 상태를 유지한 채 새 계정의 프로필을 받는다.
                Logger.setting.info("Apple 로그인 완료")
                return fetchProfile()
            case let .failure(error):
                state.isSigningIn = false
                state.presentAlert(.appleSignInFailure(error))
                return .none
            }

        case let .fetchProfileResponse(result):
            state.isSigningIn = false
            switch result {
            case let .success(profile):
                return .send(.delegate(.accountChanged(profile)))
            case .failure:
                // 로그인은 됐으니 실패를 알리지 않는다. 소유자가 다시 불러오고 실패하면 재시도를 맡는다.
                return .send(.delegate(.accountChanged(nil)))
            }

        case let .withdrawResponse(result):
            switch result {
            case .success:
                Logger.setting.info("탈퇴 완료")
                return .send(.delegate(.logout))
            case let .failure(error):
                state.presentAlert(.withdrawalFailure(error))
                return .none
            }
        }
    }

    /// 뷰의 `.task`가 끝나면(화면이 사라지면) 구독도 끝난다.
    private func observeSetting() -> Effect<Action> {
        .run { send in
            for await setting in observeSettingUseCase.execute() {
                await send(.effect(.settingChanged(setting)))
            }
        }
    }

    /// 취소하지 않는다. 연달아 바꿔도 값마다 기기에 써야 하고, 서버에 보내는 순서는 Repository가 맞춘다.
    private func updateSetting(_ setting: AppSetting) -> Effect<Action> {
        .run { send in
            await send(.effect(.updateSettingResponse(updateSettingUseCase.execute(setting))))
        }
    }

    private func signIn(_ request: AppleSignInRequest) -> Effect<Action> {
        .run { send in
            await send(.effect(.signInResponse(signInWithAppleUseCase.execute(request))))
        }
        .cancellable(id: CancelID.signIn, cancelInFlight: true)
    }

    private func fetchProfile() -> Effect<Action> {
        .run { send in
            await send(.effect(.fetchProfileResponse(fetchProfileUseCase.execute())))
        }
        .cancellable(id: CancelID.fetchProfile, cancelInFlight: true)
    }

    private func logout() -> Effect<Action> {
        .run { send in
            // 서버 요청이 실패해도 이 기기에서는 로그아웃된 것으로 본다.
            _ = await logoutUseCase.execute()
            await send(.delegate(.logout))
        }
    }

    private func withdraw() -> Effect<Action> {
        .run { send in
            await send(.effect(.withdrawResponse(withdrawUseCase.execute())))
        }
    }
}

extension SettingFeature.Destination.State: Equatable {}

private extension SettingFeature.State {
    /// 알릴 필요가 없는 에러(nil)면 띄우지 않고, 지금 띄운 시트도 그대로 둔다.
    mutating func presentAlert(_ alert: AlertState<SettingFeature.Alert>?) {
        guard let alert else { return }
        destination = .alert(alert)
    }
}
