import Dependencies
import DependenciesMacros

/// 저장된 기기 설정을 불러온다.
@DependencyClient
public struct FetchSettingUseCase: Sendable {
    public var execute: @Sendable () async throws -> AppSetting
}

extension DependencyValues {
    public var fetchSettingUseCase: FetchSettingUseCase {
        get { self[FetchSettingUseCase.self] }
        set { self[FetchSettingUseCase.self] = newValue }
    }
}

extension FetchSettingUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: {
            @Dependency(\.settingRepository) var settingRepository
            return try await settingRepository.fetchSetting()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
