import CoreNetwork

/// 인증 API. 지금은 `TokenManager`가 쓰는 토큰 갱신만 있다.
enum AuthEndpoint: APIEndpoint, Equatable {
    case refresh(refreshToken: String)

    var path: String {
        switch self {
        case .refresh: return "/api/v1/auth/refresh"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .refresh: return .post
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case let .refresh(refreshToken): return RefreshRequestDTO(refreshToken: refreshToken)
        }
    }

    /// 갱신 요청이 인터셉터를 다시 타면 401 → 갱신 → 401로 돈다.
    var requiresAuth: Bool { false }
}
