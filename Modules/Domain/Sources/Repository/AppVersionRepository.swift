import Dependencies
import DependenciesMacros

/// 앱 버전 포트. 구현(`liveValue`)은 Data 모듈에 둔다.
/// Feature는 이 타입을 직접 쓰지 않고 `CheckAppUpdateUseCase`를 통해서만 접근한다.
@DependencyClient
public struct AppVersionRepository: Sendable {
    /// 설치된 버전을 서버에 보내 업데이트 정책을 받는다.
    public var checkUpdate: @Sendable () async -> Result<AppUpdate, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var appVersionRepository: AppVersionRepository {
        get { self[AppVersionRepository.self] }
        set { self[AppVersionRepository.self] = newValue }
    }
}

extension AppVersionRepository: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        checkUpdate: { .success(.upToDate) }
    )
}
