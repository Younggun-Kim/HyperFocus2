import AuthenticationServices
import ComposableArchitecture
import Domain
import Foundation
import Testing
@testable import Setting

struct AppleSignInResultTests {
    @Test func 사용자가_취소하면_canceled다() {
        #expect(AppleSignInResult(ASAuthorizationError(.canceled)) == .canceled)
    }

    @Test func 그_밖의_에러는_코드를_담아_failed다() {
        let error = ASAuthorizationError(.failed)
        #expect(AppleSignInResult(error) == .failed(code: ASAuthorizationError.Code.failed.rawValue))
    }

    @Test func 토큰과_코드가_모두_있어야_서버_요청을_만든다() {
        let complete = AppleCredential(
            userID: "test-user", identityToken: "test-token", authorizationCode: "test-code", name: "테스트", email: nil
        )
        #expect(complete.signInRequest == AppleSignInRequest(
            identityToken: "test-token", authorizationCode: "test-code", name: "테스트", email: nil
        ))

        let noCode = AppleCredential(
            userID: "test-user", identityToken: "test-token", authorizationCode: nil, name: nil, email: nil
        )
        #expect(noCode.signInRequest == nil)
    }

    @Test func 이름은_성과_이름을_붙이고_비어_있으면_nil이다() {
        var components = PersonNameComponents()
        #expect(components.appleDisplayName == nil)
        components.familyName = "홍"
        components.givenName = "길동"
        #expect(components.appleDisplayName == "홍길동")
    }
}

@MainActor
struct SettingAppleSignInTests {
    private let credential = AppleCredential(
        userID: "test-user", identityToken: "test-token", authorizationCode: "test-code", name: nil, email: nil
    )

    @Test func 인증되면_UseCase로_보내고_끝나면_로그인_중을_푼다() async {
        let received = LockIsolated<AppleSignInRequest?>(nil)
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.signInWithAppleUseCase.execute = { received.setValue($0) }
        }

        await store.send(.appleSignInCompleted(.authorized(credential))) {
            $0.isSigningIn = true
        }
        await store.receive(.appleSignInSucceeded) {
            $0.isSigningIn = false
        }
        #expect(received.value == credential.signInRequest)
    }

    @Test func 서버_로그인이_실패하면_알림을_띄운다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.signInWithAppleUseCase.execute = { _ in throw DomainError.offline }
        }

        await store.send(.appleSignInCompleted(.authorized(credential))) {
            $0.isSigningIn = true
        }
        await store.receive(.appleSignInFailed(.offline)) {
            $0.isSigningIn = false
            $0.destination = .alert(.appleSignInFailure(.offline))
        }
    }

    @Test func 로그인_중에_다시_인증되면_무시한다() async {
        var state = SettingFeature.State()
        state.isSigningIn = true
        let store = TestStore(initialState: state) {
            SettingFeature()
        }

        await store.send(.appleSignInCompleted(.authorized(credential)))
    }

    @Test func 토큰이나_코드가_없으면_요청하지_않고_알림을_띄운다() async {
        let noCode = AppleCredential(
            userID: "test-user", identityToken: "test-token", authorizationCode: nil, name: nil, email: nil
        )
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.appleSignInCompleted(.authorized(noCode))) {
            $0.destination = .alert(.appleSignInFailure(.unknown))
        }
    }

    @Test func 사용자가_취소하면_아무것도_하지_않는다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.appleSignInCompleted(.canceled))
    }

    @Test func Apple_인증이_실패하면_알림을_띄운다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.appleSignInCompleted(.failed(code: ASAuthorizationError.Code.failed.rawValue))) {
            $0.destination = .alert(.appleSignInFailure(.unknown))
        }
    }
}
