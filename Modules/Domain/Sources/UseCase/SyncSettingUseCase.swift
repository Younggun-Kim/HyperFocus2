import Dependencies
import DependenciesMacros

/// 로그인된 계정의 기기 설정을 서버와 맞춘다. 맞춘 값은 `ObserveSettingUseCase`로도 전달된다.
///
/// 언제 맞출지(로그인 직후, 앱이 다시 활성화될 때)는 App의 `RootFeature`가 정한다.
@DependencyClient
public struct SyncSettingUseCase: Sendable {
    public var execute: @Sendable (_ accountId: String) async -> Result<AppSetting, DomainError> = { _ in .failure(.unknown) }
}

extension DependencyValues {
    public var syncSettingUseCase: SyncSettingUseCase {
        get { self[SyncSettingUseCase.self] }
        set { self[SyncSettingUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
// 선언과 같은 파일에 두어 Feature가 선언을 참조하면 liveValue도 함께 링크되게 한다.
extension SyncSettingUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: { accountId in
            @Dependency(\.settingRepository) var settingRepository
            return await settingRepository.syncSetting(accountId)
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
