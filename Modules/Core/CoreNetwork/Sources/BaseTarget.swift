import Foundation
import Moya

/// 기본 TargetType 프로토콜
/// 모든 API Target은 이 프로토콜을 준수해야 합니다.
public protocol BaseTarget: TargetType {}

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
}
