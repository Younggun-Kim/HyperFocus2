import AuthenticationServices
import Domain
import Foundation
import os

/// Sign in with Apple 결과에서 Reducer가 쓸 값만 꺼낸 것.
/// `ASAuthorization`은 `Sendable`·`Equatable`이 아니라 Action에 그대로 담을 수 없다.
public enum AppleSignInResult: Equatable, Sendable {
    case authorized(AppleCredential)
    /// 사용자가 시트를 닫았다. 실패가 아니다.
    case canceled
    /// `ASAuthorizationError.Code` 등 원본 에러 코드
    case failed(code: Int)
}

/// 서버로 보낼 Apple 자격 증명. 로그에는 값이 아니라 **있는지만** 남긴다.
public struct AppleCredential: Equatable, Sendable {
    public let userID: String
    public let identityToken: String?
    public let authorizationCode: String?
    /// 첫 로그인 때만 온다.
    public let name: String?
    /// 첫 로그인 때만 온다.
    public let email: String?
}

extension AppleCredential {
    /// 서버에 보낼 값. 토큰이나 코드가 없으면 서버가 검증할 수 없으므로 nil.
    var signInRequest: AppleSignInRequest? {
        guard let identityToken, let authorizationCode else { return nil }
        return AppleSignInRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            name: name,
            email: email
        )
    }
}

extension PersonNameComponents {
    /// 원본 앱과 같이 성 + 이름을 붙인다. 둘 다 없으면 nil.
    var appleDisplayName: String? {
        let name = (familyName ?? "") + (givenName ?? "")
        return name.isEmpty ? nil : name
    }
}

extension AppleSignInResult {
    init(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                self = .failed(code: ASAuthorizationError.Code.unknown.rawValue)
                return
            }
            self = .authorized(AppleCredential(
                userID: credential.user,
                identityToken: credential.identityToken.flatMap { String(data: $0, encoding: .utf8) },
                authorizationCode: credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) },
                name: credential.fullName?.appleDisplayName,
                email: credential.email
            ))
        case .failure(let error):
            self.init(error)
        }
    }

    init(_ error: any Error) {
        if let error = error as? ASAuthorizationError, error.code == .canceled {
            self = .canceled
        } else {
            self = .failed(code: (error as NSError).code)
        }
    }
}

extension Logger {
    /// Setting 모듈 공통 로거. subsystem은 번들 ID, category는 모듈 이름
    static let setting = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hyperfocus.timer", category: "Setting")
}
