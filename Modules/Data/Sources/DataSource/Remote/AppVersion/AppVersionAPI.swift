import CoreNetwork

/// 앱 버전 API. 이 enum은 이름 공간이고, API 하나가 타입 하나다.
enum AppVersionAPI {
    /// 설치된 버전을 보내 업데이트 정책을 받는다.
    struct Check: APIEndpoint, Equatable {
        typealias Response = AppVersionCheckResponseDTO

        let request: AppVersionCheckRequestDTO

        var path: String { "/api/v1/app/version/check" }
        var method: HTTPMethod { .post }
        var body: (any Encodable & Sendable)? { request }
        /// 로그인 확인과 동시에 보낸다. 계정과 상관없는 정보라 토큰 없이 보낸다.
        var requiresAuth: Bool { false }
    }
}
