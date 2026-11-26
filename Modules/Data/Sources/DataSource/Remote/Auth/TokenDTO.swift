import CoreNetwork
import Domain

struct RefreshRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

struct TokenResponseDTO: Decodable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
}

extension TokenResponseDTO {
    func toAuthToken() -> AuthToken {
        AuthToken(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType)
    }
}

struct AnonymousLoginRequestDTO: Encodable, Sendable, Equatable {
    let deviceId: String
}

/// name·email은 첫 로그인 때만 Apple이 준다. 없으면 서버에 빈 문자열로 보낸다(원본 앱과 같은 계약).
struct AppleLinkRequestDTO: Encodable, Sendable, Equatable {
    let identityToken: String
    let authorizationCode: String
    let name: String
    let email: String
}

struct AppleLoginRequestDTO: Encodable, Sendable, Equatable {
    let identityToken: String
    let name: String
    let email: String
}

extension AppleLinkRequestDTO {
    init(_ request: AppleSignInRequest) {
        self.init(
            identityToken: request.identityToken,
            authorizationCode: request.authorizationCode,
            name: request.name ?? "",
            email: request.email ?? ""
        )
    }
}

extension AppleLoginRequestDTO {
    init(_ request: AppleSignInRequest) {
        self.init(identityToken: request.identityToken, name: request.name ?? "", email: request.email ?? "")
    }
}
