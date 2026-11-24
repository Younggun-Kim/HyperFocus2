import ComposableArchitecture
import SessionHistory
import Testing

@MainActor
struct SessionLogHomeFeatureTests {
    @Test func 초기_상태로_만들어진다() {
        let store = TestStore(initialState: SessionLogHomeFeature.State()) {
            SessionLogHomeFeature()
        }

        #expect(store.state == SessionLogHomeFeature.State())
    }
}
