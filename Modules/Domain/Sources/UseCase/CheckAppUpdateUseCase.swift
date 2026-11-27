import Dependencies
import DependenciesMacros

/// 이 버전을 계속 써도 되는지 서버에 묻는다.
@DependencyClient
public struct CheckAppUpdateUseCase: Sendable {
    public var execute: @Sendable () async -> Result<AppUpdate, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var checkAppUpdateUseCase: CheckAppUpdateUseCase {
        get { self[CheckAppUpdateUseCase.self] }
        set { self[CheckAppUpdateUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
extension CheckAppUpdateUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: {
            @Dependency(\.appVersionRepository) var appVersionRepository

            return await appVersionRepository.checkUpdate()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
