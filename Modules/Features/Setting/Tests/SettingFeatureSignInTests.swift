import AuthenticationServices
import ComposableArchitecture
import Domain
import Foundation
import Testing
@testable import Setting

/// `Result<Void, _>`의 `.success`/`.failure`까지 내려가는 key path는 Swift 6.4.2 컴파일러가 IRGen에서 크래시한다.
/// 그래서 `\.effect.signInResponse`까지만 맞추고 결과는 상태 변화로 검증한다.
@MainActor
struct SettingFeatureSignInTests {
    private let credential = AppleCredential(
        userID: "test-user", identityToken: "test-token", authorizationCode: "test-code", name: nil, email: nil
    )

    @Test func 인증되면_UseCase로_보내고_끝나면_계정이_바뀌었다고_알린다() async {
        let received = LockIsolated<AppleSignInRequest?>(nil)
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.signInWithAppleUseCase.execute = {
                received.setValue($0)
                return .success(())
            }
        }

        await store.send(.view(.appleSignInCompleted(.authorized(credential)))) {
            $0.isSigningIn = true
        }
        await store.receive(\.effect.signInResponse) {
            $0.isSigningIn = false
        }
        await store.receive(\.delegate.accountChanged)
        #expect(received.value == credential.signInRequest)
    }

    @Test func 서버_로그인이_실패하면_알림을_띄운다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.signInWithAppleUseCase.execute = { _ in .failure(.offline) }
        }

        await store.send(.view(.appleSignInCompleted(.authorized(credential)))) {
            $0.isSigningIn = true
        }
        await store.receive(\.effect.signInResponse) {
            $0.isSigningIn = false
            $0.destination = .alert(AlertState.appleSignInFailure(.offline)!)
        }
    }

    @Test func 서버_로그인이_취소되면_알리지_않고_로그인_중만_푼다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.signInWithAppleUseCase.execute = { _ in .failure(.cancelled) }
        }

        await store.send(.view(.appleSignInCompleted(.authorized(credential)))) {
            $0.isSigningIn = true
        }
        await store.receive(\.effect.signInResponse) {
            $0.isSigningIn = false
        }
    }

    @Test func 로그인_중에_다시_인증되면_무시한다() async {
        var state = SettingFeature.State()
        state.isSigningIn = true
        let store = TestStore(initialState: state) {
            SettingFeature()
        }

        await store.send(.view(.appleSignInCompleted(.authorized(credential))))
    }

    @Test func 토큰이나_코드가_없으면_요청하지_않고_알림을_띄운다() async {
        let noCode = AppleCredential(
            userID: "test-user", identityToken: "test-token", authorizationCode: nil, name: nil, email: nil
        )
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.view(.appleSignInCompleted(.authorized(noCode)))) {
            $0.destination = .alert(AlertState.appleSignInFailure(.unknown)!)
        }
    }

    @Test func 사용자가_취소하면_아무것도_하지_않는다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.view(.appleSignInCompleted(.canceled)))
    }

    @Test func Apple_인증이_실패하면_알림을_띄운다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.view(.appleSignInCompleted(.failed(code: ASAuthorizationError.Code.failed.rawValue)))) {
            $0.destination = .alert(AlertState.appleSignInFailure(.unknown)!)
        }
    }
}
