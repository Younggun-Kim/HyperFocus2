import Dependencies
import DependenciesMacros

/// 집중 기록 포트. 구현(`liveValue`)은 Data 모듈에 둔다.
/// Feature는 이 타입을 직접 쓰지 않고 `FetchSessionLogDashboardUseCase`를 통해서만 접근한다.
@DependencyClient
public struct SessionLogRepository: Sendable {
    public var fetchDashboard: @Sendable () async -> Result<SessionLogDashboard, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var sessionLogRepository: SessionLogRepository {
        get { self[SessionLogRepository.self] }
        set { self[SessionLogRepository.self] = newValue }
    }
}

extension SessionLogRepository: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        fetchDashboard: { .success(SessionLogDashboard(isEmpty: true)) }
    )
}
