import Foundation

/// 서버가 정한 이 버전의 업데이트 정책.
///
/// 기기마다 하나뿐인 값이라 `Identifiable`을 채택하지 않는다.
public struct AppUpdate: Sendable, Equatable {
    public enum Policy: Sendable, Equatable {
        /// 지금 버전으로 계속 쓴다. `Optional.none`과 헷갈리지 않게 `none`이라 부르지 않는다.
        case upToDate
        /// 업데이트를 권하지만 지금 버전으로도 쓸 수 있다.
        case optional
        /// 업데이트해야 쓸 수 있다.
        case required
    }

    public let policy: Policy
    /// 서버가 알려 준 스토어 주소. 없으면 화면이 기본 주소를 쓴다.
    public let storeURL: URL?

    public init(policy: Policy, storeURL: URL? = nil) {
        self.policy = policy
        self.storeURL = storeURL
    }
}

extension AppUpdate {
    /// 업데이트할 필요가 없다.
    public static let upToDate = AppUpdate(policy: .upToDate)
}
