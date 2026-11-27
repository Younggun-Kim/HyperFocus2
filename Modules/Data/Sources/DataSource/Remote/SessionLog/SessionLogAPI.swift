import CoreNetwork

/// 집중 기록 API. 이 enum은 이름 공간이고, API 하나가 타입 하나다.
enum SessionLogAPI {
    struct FetchDashboard: APIEndpoint, Equatable {
        typealias Response = DashboardResponseDTO

        var path: String { "/api/v1/log/dashboard" }
        var method: HTTPMethod { .get }
    }
}
