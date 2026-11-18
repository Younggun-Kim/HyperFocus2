import ComposableArchitecture
import Data
import SwiftUI
import SessionHistory

@main
struct SessionHistoryExampleApp: App {
    init() {
        // Data가 링크되어 있으므로 주입하지 않으면 liveValue(실제 저장소)를 쓴다.
        // 예제 앱은 mock을 명시적으로 넣는다.
        prepareDependencies {
            $0.sampleClient.getSamples = {
                [Sample(id: "example-1"), Sample(id: "example-2"), Sample(id: "example-3")]
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            SessionHistoryView(
                store: Store(initialState: SessionHistoryFeature.State()) {
                    SessionHistoryFeature()
                }
            )
        }
    }
}
