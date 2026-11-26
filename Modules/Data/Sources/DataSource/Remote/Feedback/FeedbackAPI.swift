import CoreNetwork

/// 피드백 API. 이 enum은 이름 공간이고, API 하나가 타입 하나다.
enum FeedbackAPI {
    /// 응답 본문은 쓰지 않는다. 성공 여부만 본다.
    struct Send: APIEndpoint, Equatable {
        typealias Response = EmptyResponse

        let request: FeedbackRequestDTO

        var path: String { "/api/v1/feedback" }
        var method: HTTPMethod { .post }
        var body: (any Encodable & Sendable)? { request }
    }
}
