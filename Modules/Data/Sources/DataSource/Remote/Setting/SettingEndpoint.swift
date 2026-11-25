import CoreNetwork

enum SettingEndpoint: APIEndpoint, Equatable {
    case fetch
    case update(SettingRequestDTO)

    var path: String { "/api/v1/settings" }

    var method: HTTPMethod {
        switch self {
        case .fetch: return .get
        case .update: return .patch
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .fetch: return nil
        case let .update(request): return request
        }
    }
}
