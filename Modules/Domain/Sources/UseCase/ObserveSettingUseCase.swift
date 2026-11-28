import Dependencies
import DependenciesMacros

/// 지금 적용할 기기 설정을 받는다. 지금 값을 먼저 보내고, 바뀔 때마다 다시 보낸다.
///
/// 네트워크를 기다리지 않는다. 화면은 구독만 하면 되고, 값이 어디서 왔는지는 알 필요가 없다.
@DependencyClient
public struct ObserveSettingUseCase: Sendable {
    public var execute: @Sendable () -> AsyncStream<AppSetting> = { AsyncStream { $0.finish() } }
}

extension DependencyValues {
    public var observeSettingUseCase: ObserveSettingUseCase {
        get { self[ObserveSettingUseCase.self] }
        set { self[ObserveSettingUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
// 선언과 같은 파일에 두어 Feature가 선언을 참조하면 liveValue도 함께 링크되게 한다.
extension ObserveSettingUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: {
            @Dependency(\.settingRepository) var settingRepository
            return settingRepository.observeSetting()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
