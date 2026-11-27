import ComposableArchitecture
import Domain
import Foundation
import os

@Reducer
public struct SettingFeature {

    @Dependency(\.fetchSettingUseCase) var fetchSettingUseCase
    @Dependency(\.signInWithAppleUseCase) var signInWithAppleUseCase
    @Dependency(\.updateSettingUseCase) var updateSettingUseCase
    @Dependency(\.logoutUseCase) var logoutUseCase

    /// 설정 화면에서 띄우는 시트.
    @Reducer
    public enum Destination {
        /// 개인정보처리방침, 이용약관. 로직이 없어 주소만 들고 있다.
        @ReducerCaseIgnored
        case webPage(URL)
        case feedback(FeedbackFeature)
        case alert(AlertState<Never>)
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

    public enum Action: Equatable {
        case onAppear
        case deviceSettingChanged(type: SettingMenuType.DeviceSetting, isOn: Bool)
        case aboutUsTapped(SettingMenuType.AboutUs)
        case appleSignInCompleted(AppleSignInResult)
        case appleSignInSucceeded
        case appleSignInFailed(DomainError)
        case settingLoaded(AppSetting)
        case settingLoadFailed(DomainError)
        case settingSaved(AppSetting)
        case settingSaveFailed(DomainError)
        case logoutTapped
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            /// 로그인된 계정이 바뀌었다.
            case accountChanged
            /// 로그아웃했다.
            case logout
        }
    }

    enum CancelID {
        case load
        case save
        case signIn
    }
    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    switch await fetchSettingUseCase.execute() {
                    case .success(let setting): await send(.settingLoaded(setting))
                    case .failure(let error): await send(.settingLoadFailed(error))
                    }
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .deviceSettingChanged(type, isOn):
                guard state.setting[type] != isOn else { return .none }
                state.setting[type] = isOn
                // 사용자가 바꾼 값이 이긴다. 늦게 도착한 조회 결과가 덮어쓰지 않게 조회를 취소한다.
                // 저장은 매번 전체 값을 보내므로, 앞선 저장을 취소하고 마지막 값만 보내도 된다.
                return .merge(
                    .cancel(id: CancelID.load),
                    .run { [setting = state.setting] send in
                        switch await updateSettingUseCase.execute(setting) {
                        case .success(let saved): await send(.settingSaved(saved))
                        case .failure(let error): await send(.settingSaveFailed(error))
                        }
                    }
                    .cancellable(id: CancelID.save, cancelInFlight: true)
                )

            case let .settingLoaded(setting), let .settingSaved(setting):
                state.setting = setting
                state.savedSetting = setting
                return .none

            case let .settingLoadFailed(error):
                // 불러오지 못해도 화면은 기본값으로 쓸 수 있다. 인증 문제는 RootFeature가 처리한다.
                guard let alert = AlertState.settingFailure(error, action: .load) else { return .none }
                state.destination = .alert(alert)
                return .none

            case let .settingSaveFailed(error):
                state.setting = state.savedSetting
                guard let alert = AlertState.settingFailure(error, action: .save) else { return .none }
                state.destination = .alert(alert)
                return .none

            case let .aboutUsTapped(item):
                if let url = item.url {
                    state.destination = .webPage(url)
                } else {
                    state.destination = .feedback(FeedbackFeature.State())
                }
                return .none

            case let .appleSignInCompleted(result):
                // 토큰, 사용자 식별자, email 값은 찍지 않는다. 있는지만 남긴다.
                switch result {
                case let .authorized(credential):
                    Logger.setting.info(
                        "Apple 인증 완료: identityToken \(credential.identityToken != nil), authorizationCode \(credential.authorizationCode != nil), email \(credential.email != nil)"
                    )
                    guard !state.isSigningIn else { return .none }
                    guard let request = credential.signInRequest else {
                        Logger.setting.error("Apple 로그인 실패: 서버에 보낼 토큰이나 코드가 없다")
                        state.destination = AlertState.appleSignInFailure(.unknown).map(Destination.State.alert)
                        return .none
                    }
                    state.isSigningIn = true
                    return .run { send in
                        switch await signInWithAppleUseCase.execute(request) {
                        case .success: await send(.appleSignInSucceeded)
                        case .failure(let error): await send(.appleSignInFailed(error))
                        }
                    }
                    .cancellable(id: CancelID.signIn, cancelInFlight: true)

                case .canceled:
                    Logger.setting.debug("Apple 로그인: 사용자가 취소")
                    return .none

                case let .failed(code):
                    Logger.setting.error("Apple 로그인 실패: code \(code)")
                    state.destination = AlertState.appleSignInFailure(.unknown).map(Destination.State.alert)
                    return .none
                }

            case .appleSignInSucceeded:
                state.isSigningIn = false
                Logger.setting.info("Apple 로그인 완료")
                return .send(.delegate(.accountChanged))

            case let .appleSignInFailed(error):
                state.isSigningIn = false
                guard let alert = AlertState.appleSignInFailure(error) else { return .none }
                state.destination = .alert(alert)
                return .none

            case .destination(.presented(.feedback(.delegate(.sent)))):
                state.destination = nil
                return .none

            case .destination, .delegate:
                return .none

            case .logoutTapped:
                return .run { send in
                    // 서버 요청이 실패해도 이 기기에서는 로그아웃된 것으로 본다.
                    _ = await logoutUseCase.execute()
                    await send(.delegate(.logout))
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension SettingFeature.Destination.State: Equatable {}
extension SettingFeature.Destination.Action: Equatable {}

extension AppSetting {
    /// 메뉴 항목 하나로 읽고 쓰는 창구. 화면과 Reducer가 같은 매핑을 쓴다.
    subscript(type: SettingMenuType.DeviceSetting) -> Bool {
        get {
            switch type {
            case .sound: soundEnabled
            case .haptic: hapticEnabled
            case .alarm: alarmEnabled
            }
        }
        set {
            switch type {
            case .sound: soundEnabled = newValue
            case .haptic: hapticEnabled = newValue
            case .alarm: alarmEnabled = newValue
            }
        }
    }
}

extension AlertState where Action == Never {
    /// Apple 로그인 실패 문구. 취소면 알리지 않으므로 nil.
    /// 로그인 중의 `unauthorized`는 세션 만료가 아니라 서버가 Apple 자격 증명을 거절한 것이므로 알린다.
    static func appleSignInFailure(_ error: DomainError) -> Self? {
        let message: String
        switch error {
        case .cancelled:
            return nil
        case .offline:
            message = "Please check your internet connection."
        case .unauthorized, .notFound, .invalid, .conflict, .unknown:
            message = "Please try again in a moment."
        }
        return AlertState {
            TextState("Couldn't sign in with Apple.")
        } actions: {
            ButtonState(role: .cancel) { TextState("OK") }
        } message: {
            TextState(message)
        }
    }

    enum SettingAction {
        case load
        case save
    }

    /// Domain 에러를 사용자 문구로 바꾼다. 알릴 필요가 없는 에러면 nil.
    static func settingFailure(_ error: DomainError, action: SettingAction) -> Self? {
        let message: String
        switch error {
        case .unauthorized, .notFound, .cancelled:
            // 인증은 앱 전역에서 처리하고, 저장된 설정이 없으면 기본값을 쓰면 된다. 취소는 알리지 않는다.
            return nil
        case .offline:
            message = "Please check your internet connection."
        case .invalid, .conflict, .unknown:
            message = "Please try again in a moment."
        }
        return AlertState {
            switch action {
            case .load: TextState("Couldn't load your settings.")
            case .save: TextState("Couldn't save your settings.")
            }
        } actions: {
            ButtonState(role: .cancel) { TextState("OK") }
        } message: {
            TextState(message)
        }
    }
}
