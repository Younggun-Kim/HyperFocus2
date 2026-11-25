import Foundation
import Moya

/// CoreNetwork 안에서 Moya에 넘기는 TargetType.
/// 바깥에는 `APIEndpoint`만 공개하고, `APIService`가 `EndpointTarget`으로 감싸서 이 타입으로 바꾼다.
protocol BaseTarget: TargetType {
    /// `true`면 `Authorization` 헤더를 붙여 보내고, 토큰이 없으면 요청을 보내지 않는다.
    var requiresAuth: Bool { get }
}

extension BaseTarget {
    /// 기본 헤더
    var headers: [String: String]? {
        return NetworkHeader.basic
    }

    /// 기본 샘플 데이터 (테스트용)
    var sampleData: Data {
        return Data()
    }

    /// 기본 validation 타입
    var validationType: ValidationType {
        return .successCodes
    }

    var requiresAuth: Bool {
        return true
    }
}

/// `APIEndpoint`에 baseURL을 붙여 Moya가 보낼 수 있는 형태로 만든다.
struct EndpointTarget: BaseTarget {
    let baseURL: URL
    let endpoint: any APIEndpoint

    var path: String { endpoint.path }

    var method: Moya.Method {
        switch endpoint.method {
        case .get: return .get
        case .post: return .post
        case .put: return .put
        case .patch: return .patch
        case .delete: return .delete
        }
    }

    var task: Moya.Task {
        guard let body = endpoint.body else { return .requestPlain }
        return .requestJSONEncodable(body)
    }

    var requiresAuth: Bool { endpoint.requiresAuth }
}
