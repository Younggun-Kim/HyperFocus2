import CoreNetwork

enum FeedbackAPI: APIEndpoint, Equatable {
    case send(FeedbackRequestDTO)
}

extension FeedbackAPI {
    var path: String { "/api/v1/feedback" }
    var method: HTTPMethod { .post }

    var body: (any Encodable & Sendable)? {
        switch self {
        case let .send(request): return request
        }
    }
}
