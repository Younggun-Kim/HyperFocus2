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
        /// 화면에 보이는 값. 토글하면 저장 결과를 기다리지 않고 바로 바뀐다.
        var setting: AppSetting
        /// 서버가 마지막으로 확정한 값. 저장에 실패하면 이 값으로 되돌린다.
        var savedSetting: AppSetting
        /// Apple 로그인 요청을 서버에 보내는 중. 버튼을 또 눌러도 한 번만 보낸다.
        var isSigningIn = false
        /// 지금 로그인된 계정. 소유자가 넘겨준 참조라 여기서는 읽기만 한다.
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
            self.savedSetting = setting
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
            case onAppear
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
            case fetchSettingResponse(Result<AppSetting, DomainError>)
            case updateSettingResponse(Result<AppSetting, DomainError>)
            case signInResponse(Result<Void, DomainError>)
            case withdrawResponse(Result<Void, DomainError>)
        }

        @CasePathable
        public enum Delegate: Equatable {
            /// 로그인된 계정이 바뀌었다.
            case accountChanged
            /// 로그아웃했다.(or 탈퇴)
            case logout
        }
    }

    enum CancelID {
        case load
        case save
        case signIn
    }

    @Dependency(\.fetchSettingUseCase) var fetchSettingUseCase
    @Dependency(\.updateSettingUseCase) var updateSettingUseCase
    @Dependency(\.signInWithAppleUseCase) var signInWithAppleUseCase
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
        case .onAppear:
            return fetchSetting()

        case let .deviceSettingChanged(type, isOn):
            guard state.setting[type] != isOn else { return .none }
            state.setting[type] = isOn
            // 사용자가 바꾼 값이 이긴다. 늦게 도착한 조회 결과가 덮어쓰지 않게 조회를 취소한다.
            return .merge(
                .cancel(id: CancelID.load),
                updateSetting(state.setting)
            )

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
        case let .fetchSettingResponse(result):
            switch result {
            case let .success(setting):
                state.applySaved(setting)
            case let .failure(error):
                // 불러오지 못해도 화면은 기본값으로 쓸 수 있다.
                state.presentAlert(.settingLoadFailure(error))
            }
            return .none

        case let .updateSettingResponse(result):
            switch result {
            case let .success(setting):
                state.applySaved(setting)
            case let .failure(error):
                state.setting = state.savedSetting
                state.presentAlert(.settingSaveFailure(error))
            }
            return .none

        case let .signInResponse(result):
            state.isSigningIn = false
            switch result {
            case .success:
                Logger.setting.info("Apple 로그인 완료")
                return .send(.delegate(.accountChanged))
            case let .failure(error):
                state.presentAlert(.appleSignInFailure(error))
                return .none
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

    private func fetchSetting() -> Effect<Action> {
        .run { send in
            await send(.effect(.fetchSettingResponse(fetchSettingUseCase.execute())))
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

    /// 저장은 매번 전체 값을 보내므로, 앞선 저장을 취소하고 마지막 값만 보내도 된다.
    private func updateSetting(_ setting: AppSetting) -> Effect<Action> {
        .run { send in
            await send(.effect(.updateSettingResponse(updateSettingUseCase.execute(setting))))
        }
        .cancellable(id: CancelID.save, cancelInFlight: true)
    }

    private func signIn(_ request: AppleSignInRequest) -> Effect<Action> {
        .run { send in
            await send(.effect(.signInResponse(signInWithAppleUseCase.execute(request))))
        }
        .cancellable(id: CancelID.signIn, cancelInFlight: true)
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
    /// 서버가 확정한 값을 화면 값과 기준 값에 함께 반영한다.
    mutating func applySaved(_ setting: AppSetting) {
        self.setting = setting
        self.savedSetting = setting
    }

    /// 알릴 필요가 없는 에러(nil)면 띄우지 않고, 지금 띄운 시트도 그대로 둔다.
    mutating func presentAlert(_ alert: AlertState<SettingFeature.Alert>?) {
        guard let alert else { return }
        destination = .alert(alert)
    }
}
