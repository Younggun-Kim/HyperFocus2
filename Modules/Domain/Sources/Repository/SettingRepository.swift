import Dependencies
import DependenciesMacros

/// 기기 설정 포트. 구현(`liveValue`)은 Data 모듈에 둔다.
///
/// 기기에 남긴 값이 기준이고, 서버와는 동기화만 한다. 바꾼 값은 바로 적용되고, 서버에 닿지 못해도 사라지지 않는다.
/// Feature는 이 타입을 직접 쓰지 않고 `ObserveSettingUseCase`, `UpdateSettingUseCase`, `SyncSettingUseCase`를 통해서만 접근한다.
@DependencyClient
public struct SettingRepository: Sendable {
    /// 지금 값을 먼저 보내고, 바뀔 때마다 다시 보낸다. 저장된 값이 없으면 `AppSetting.default`를 보낸다.
    public var observeSetting: @Sendable () -> AsyncStream<AppSetting> = { AsyncStream { $0.finish() } }
    /// 기기에 바로 반영한다. 서버에 보내지 못한 변경은 남겨 두었다가 다음 동기화에서 보낸다.
    public var updateSetting: @Sendable (_ setting: AppSetting) async -> Result<Void, DomainError> = { _ in .failure(.unknown) }
    /// 계정의 값을 서버와 맞춘다. 보내지 못한 변경이 있으면 먼저 보내고, 없으면 서버 값을 받는다.
    /// 다른 계정의 값이 남아 있으면 버리고 이 계정의 값으로 바꾼다.
    public var syncSetting: @Sendable (_ accountId: String) async -> Result<AppSetting, DomainError> = { _ in .failure(.unknown) }
}

extension DependencyValues {
    public var settingRepository: SettingRepository {
        get { self[SettingRepository.self] }
        set { self[SettingRepository.self] = newValue }
    }
}

extension SettingRepository: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue: Self = {
        let current = LockIsolated(AppSetting(soundEnabled: true, hapticEnabled: true, alarmEnabled: false))
        return Self(
            observeSetting: { AsyncStream { $0.yield(current.value) } },
            updateSetting: { setting in
                current.setValue(setting)
                return .success(())
            },
            syncSetting: { _ in .success(current.value) }
        )
    }()
}
