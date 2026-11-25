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
                try await Task.sleep(for: .seconds(1))
            }
            $0.settingRepository.fetchSetting = {
                try await Task.sleep(for: .seconds(1))
                return AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: true)
            }
            $0.settingRepository.updateSetting = { setting in
                try await Task.sleep(for: .milliseconds(500))
                return setting
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
