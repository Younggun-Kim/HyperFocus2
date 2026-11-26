/// 서버로 보낼 Sign in with Apple 자격 증명.
///
/// Feature가 Apple 프레임워크의 결과를 이 타입으로 바꿔 넘긴다. 값은 로그에 남기지 않는다.
public struct AppleSignInRequest: Equatable, Sendable {
    public let identityToken: String
    public let authorizationCode: String
    /// 첫 로그인 때만 온다.
    public let name: String?
    /// 첫 로그인 때만 온다.
    public let email: String?

    public init(identityToken: String, authorizationCode: String, name: String?, email: String?) {
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.name = name
        self.email = email
    }
}
