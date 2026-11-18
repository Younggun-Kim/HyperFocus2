import ComposableArchitecture
import FocusTimer
import SwiftUI

@main
struct FocusTimerExampleApp: App {
    var body: some Scene {
        WindowGroup {
            // 예제 앱에서는 결과를 빨리 보도록 5초짜리 타이머로 띄운다.
            FocusTimerView(
                store: Store(initialState: FocusTimerFeature.State(duration: 5)) {
                    FocusTimerFeature()
                }
            )
        }
    }
}
