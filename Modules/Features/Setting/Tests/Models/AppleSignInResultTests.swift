import AuthenticationServices
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
