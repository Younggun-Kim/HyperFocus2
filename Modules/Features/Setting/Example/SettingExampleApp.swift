import ComposableArchitecture
import Domain
import Setting
import SwiftUI

@main
struct SettingExampleApp: App {
    init() {
        // Example은 Data를 링크하지 않는다. Repository 포트에 mock을 넣으면 UseCase는 실제 로직대로 동작한다.
        prepareDependencies {
            $0.feedbackRepository.sendFeedback = { _, _ in
                try? await Task.sleep(for: .seconds(1))
                return .success(())
            }
            // 기기에 저장된 값을 흉내 낸다. 바꾼 값은 구독자에게 다시 보낸다.
            let (stream, continuation) = AsyncStream<AppSetting>.makeStream(bufferingPolicy: .bufferingNewest(1))
            continuation.yield(AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: true))
            $0.settingRepository.observeSetting = { stream }
            $0.settingRepository.updateSetting = { setting in
                continuation.yield(setting)
                return .success(())
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            SettingView(
                store: Store(initialState: SettingFeature.State()) {
                    SettingFeature()
                }
            )
        }
    }
}
