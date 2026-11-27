import CoreNetwork

/// 인증 API. 이 enum은 이름 공간이고, API 하나가 타입 하나다. 응답은 모두 `TokenResponseDTO`다.
enum AuthAPI {
    struct Refresh: APIEndpoint, Equatable {
        typealias Response = TokenResponseDTO

        let refreshToken: String

        var path: String { "/api/v1/auth/refresh" }
        var method: HTTPMethod { .post }
        var body: (any Encodable & Sendable)? { RefreshRequestDTO(refreshToken: refreshToken) }
        /// 갱신 요청이 인터셉터를 다시 타면 401 → 갱신 → 401로 돈다.
        var requiresAuth: Bool { false }
    }

    /// 기기 식별자로 익명 계정 토큰을 받는다.
    struct Anonymous: APIEndpoint, Equatable {
        typealias Response = TokenResponseDTO

        let request: AnonymousLoginRequestDTO

        var path: String { "/api/v1/auth/anonymous" }
        var method: HTTPMethod { .post }
        var body: (any Encodable & Sendable)? { request }
        /// 토큰을 받기 위한 요청이라 보낼 토큰이 없다.
        var requiresAuth: Bool { false }
    }

    /// 익명 계정에 Apple 계정을 연동한다.
    struct LinkApple: APIEndpoint, Equatable {
        typealias Response = TokenResponseDTO

        let request: AppleLinkRequestDTO

        var path: String { "/api/v1/auth/link/apple" }
        var method: HTTPMethod { .post }
        var body: (any Encodable & Sendable)? { request }
    }

    /// 이미 연동된 Apple 계정으로 로그인한다. 연동과 같이 익명 토큰을 붙여 보낸다.
    struct LoginApple: APIEndpoint, Equatable {
        typealias Response = TokenResponseDTO

        let request: AppleLoginRequestDTO

        var path: String { "/api/v1/auth/login/apple" }
        var method: HTTPMethod { .post }
        var body: (any Encodable & Sendable)? { request }
    }

    struct Me: APIEndpoint, Equatable {
        typealias Response = ProfileResponseDTO

        var path: String { "/api/v1/auth/me" }
        var method: HTTPMethod { .get }
    }
}
