import CoreNetwork

/// 인증 API. 응답은 모두 `TokenResponseDTO`다.
enum AuthAPI: APIEndpoint, Equatable {
    case refresh(refreshToken: String)
    /// 기기 식별자로 익명 계정 토큰을 받는다.
    case anonymous(AnonymousLoginRequestDTO)
    /// 익명 계정에 Apple 계정을 연동한다. 익명 토큰으로 보낸다.
    case linkApple(AppleLinkRequestDTO)
    /// 이미 연동된 Apple 계정으로 로그인한다.
    case loginApple(AppleLoginRequestDTO)
}

extension AuthAPI {
    var path: String {
        switch self {
        case .refresh: return "/api/v1/auth/refresh"
        case .anonymous: return "/api/v1/auth/anonymous"
        case .linkApple: return "/api/v1/auth/link/apple"
        case .loginApple: return "/api/v1/auth/login/apple"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .refresh, .anonymous, .linkApple, .loginApple: return .post
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case let .refresh(refreshToken): return RefreshRequestDTO(refreshToken: refreshToken)
        case let .anonymous(request): return request
        case let .linkApple(request): return request
        case let .loginApple(request): return request
        }
    }

    var requiresAuth: Bool {
        switch self {
        // 갱신 요청이 인터셉터를 다시 타면 401 → 갱신 → 401로 돈다.
        // 익명 로그인은 토큰을 받기 위한 요청이라 보낼 토큰이 없다.
        case .refresh, .anonymous: return false
        // 원본 앱과 같이 익명 토큰을 붙여 보낸다. UseCase가 익명 로그인을 먼저 끝낸다.
        case .linkApple, .loginApple: return true
        }
    }
}
