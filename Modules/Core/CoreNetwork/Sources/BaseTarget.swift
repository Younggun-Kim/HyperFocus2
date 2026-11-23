import Foundation
import Moya

/// 기본 TargetType 프로토콜
/// 모든 API Target은 이 프로토콜을 준수해야 합니다.
public protocol BaseTarget: TargetType {
    /// `true`면 `Authorization` 헤더를 붙여 보내고, 토큰이 없으면 요청을 보내지 않는다.
    var requiresAuth: Bool { get }
}

public extension BaseTarget {
    // TODO: 환경변수 주입해서 처리하도록
    var baseURL: URL {
        return URL(string: "https://example.com")!
    }

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
