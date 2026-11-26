import CoreNetwork

/// 설정 API. 이 enum은 이름 공간이고, API 하나가 타입 하나다.
enum SettingAPI {
    private static let path = "/api/v1/settings"

    struct Fetch: APIEndpoint, Equatable {
        typealias Response = SettingResponseDTO

        var path: String { SettingAPI.path }
        var method: HTTPMethod { .get }
    }

    /// 바뀐 값만이 아니라 전체 값을 보낸다. 서버가 저장한 값을 돌려준다.
    struct Update: APIEndpoint, Equatable {
        typealias Response = SettingResponseDTO

        let request: SettingRequestDTO

        var path: String { SettingAPI.path }
        var method: HTTPMethod { .patch }
        var body: (any Encodable & Sendable)? { request }
    }
}
