import Dependencies
import DependenciesMacros

/// 저장된 기기 설정을 불러온다.
@DependencyClient
public struct FetchSettingUseCase: Sendable {
    public var execute: @Sendable () async -> Result<AppSetting, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var fetchSettingUseCase: FetchSettingUseCase {
        get { self[FetchSettingUseCase.self] }
        set { self[FetchSettingUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
// 선언과 같은 파일에 두어 Feature가 선언을 참조하면 liveValue도 함께 링크되게 한다.
extension FetchSettingUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: {
            @Dependency(\.settingRepository) var settingRepository
            return await settingRepository.fetchSetting()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
