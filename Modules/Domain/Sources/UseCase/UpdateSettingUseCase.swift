import Dependencies
import DependenciesMacros

/// 기기 설정을 저장하고, 서버가 확정한 값을 돌려준다.
@DependencyClient
public struct UpdateSettingUseCase: Sendable {
    public var execute: @Sendable (_ setting: AppSetting) async throws -> AppSetting
}

extension DependencyValues {
    public var updateSettingUseCase: UpdateSettingUseCase {
        get { self[UpdateSettingUseCase.self] }
        set { self[UpdateSettingUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
// 선언과 같은 파일에 두어 Feature가 선언을 참조하면 liveValue도 함께 링크되게 한다.
extension UpdateSettingUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: { setting in
            @Dependency(\.settingRepository) var settingRepository
            return try await settingRepository.updateSetting(setting)
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
