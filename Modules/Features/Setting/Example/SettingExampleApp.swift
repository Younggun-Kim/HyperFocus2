import ComposableArchitecture
import Setting
import SwiftUI

@main
struct SettingExampleApp: App {
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
