import Dependencies
import DependenciesMacros

/// 기기 설정 포트. 구현(`liveValue`)은 Data 모듈에 둔다.
/// Feature는 이 타입을 직접 쓰지 않고 `FetchSettingUseCase`, `UpdateSettingUseCase`를 통해서만 접근한다.
@DependencyClient
public struct SettingRepository: Sendable {
    public var fetchSetting: @Sendable () async throws -> AppSetting
    /// 저장한 뒤 서버가 확정한 값을 돌려준다.
    public var updateSetting: @Sendable (_ setting: AppSetting) async throws -> AppSetting
}

extension DependencyValues {
    public var settingRepository: SettingRepository {
        get { self[SettingRepository.self] }
        set { self[SettingRepository.self] = newValue }
    }
}

extension SettingRepository: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        fetchSetting: { AppSetting(soundEnabled: true, hapticEnabled: true, alarmEnabled: false) },
        updateSetting: { $0 }
    )
}
