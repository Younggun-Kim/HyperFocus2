import Dependencies
import DependenciesMacros

/// 기록 탭 첫 화면의 요약을 불러온다.
@DependencyClient
public struct FetchSessionLogDashboardUseCase: Sendable {
    public var execute: @Sendable () async -> Result<SessionLogDashboard, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var fetchSessionLogDashboardUseCase: FetchSessionLogDashboardUseCase {
        get { self[FetchSessionLogDashboardUseCase.self] }
        set { self[FetchSessionLogDashboardUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
// 선언과 같은 파일에 두어 Feature가 선언을 참조하면 liveValue도 함께 링크되게 한다.
extension FetchSessionLogDashboardUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: {
            @Dependency(\.sessionLogRepository) var sessionLogRepository
            return await sessionLogRepository.fetchDashboard()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
