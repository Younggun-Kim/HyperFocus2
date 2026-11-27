import Dependencies
import DependenciesMacros

/// 세션 만료를 앱 전역 이벤트로 받는다.
///
/// 만료는 요청 하나의 실패가 아니라 계정 상태의 변화라서, 각 화면이 아니라 App의 `RootFeature`가
/// 이 스트림을 구독해 로그인 흐름으로 돌려보낸다.
@DependencyClient
public struct ObserveSessionExpiredUseCase: Sendable {
    public var execute: @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } }
}

extension DependencyValues {
    public var observeSessionExpiredUseCase: ObserveSessionExpiredUseCase {
        get { self[ObserveSessionExpiredUseCase.self] }
        set { self[ObserveSessionExpiredUseCase.self] = newValue }
    }
}

extension ObserveSessionExpiredUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: {
            @Dependency(\.authRepository) var authRepository

            return authRepository.sessionExpired()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
