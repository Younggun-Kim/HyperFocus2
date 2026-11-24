import ComposableArchitecture
import FocusTimer
import SwiftUI

@main
struct FocusTimerExampleApp: App {
    var body: some Scene {
        WindowGroup {
            FocusHomeView(
                store: Store(initialState: FocusHomeFeature.State()) {
                    FocusHomeFeature()
                }
            )
        }
    }
}
