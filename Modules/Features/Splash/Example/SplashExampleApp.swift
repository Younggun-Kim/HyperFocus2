import ComposableArchitecture
import Splash
import SwiftUI

@main
struct SplashExampleApp: App {
    /// 값을 바꾸면 Store와 화면을 새로 만들어 연출을 처음부터 다시 본다.
    @State private var replayCount = 0

    var body: some Scene {
        WindowGroup {
            SplashView(
                store: Store(initialState: SplashFeature.State()) {
                    SplashFeature()
                }
            )
            .id(replayCount)
            .onTapGesture { replayCount += 1 }
        }
    }
}
