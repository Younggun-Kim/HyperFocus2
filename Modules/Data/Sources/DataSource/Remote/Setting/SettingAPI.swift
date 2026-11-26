import CoreNetwork

enum SettingAPI: APIEndpoint, Equatable {
    case fetch
    case update(SettingRequestDTO)
}

extension SettingAPI  {
    
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
