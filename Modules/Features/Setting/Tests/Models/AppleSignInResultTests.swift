import AuthenticationServices
import ComposableArchitecture
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

    @MainActor
    @Test(arguments: [
        AppleSignInResult.canceled,
        .failed(code: ASAuthorizationError.Code.failed.rawValue),
        .authorized(AppleCredential(userID: "test-user", identityToken: "test-token", authorizationCode: nil, email: nil)),
    ])
    func 로그인_결과를_받아도_화면_상태는_바뀌지_않는다(result: AppleSignInResult) async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.appleSignInCompleted(result))
    }
}
