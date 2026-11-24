import ComposableArchitecture
import Domain
import SwiftUI
import SessionHistory

@main
struct SessionHistoryExampleApp: App {
    init() {
        // 예제 앱은 Data를 링크하지 않으므로 Repository의 live 구현이 없다.
        // Repository 포트에 mock을 넣으면 UseCase는 실제 로직(liveValue)대로 동작한다.
        prepareDependencies {
            $0.sampleRepository.fetchSamples = {
                [Sample(id: "example-1"), Sample(id: "example-2"), Sample(id: "example-3")]
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            SessionLogHomeView(
                store: Store(initialState: SessionLogHomeFeature.State()) {
                    SessionLogHomeFeature()
                }
            )
        }
    }
}
