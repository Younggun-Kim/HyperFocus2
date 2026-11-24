import ComposableArchitecture
import FocusTimer
import Testing

@MainActor
struct FocusHomeFeatureTests {
    @Test func 초기_상태로_만들어진다() {
        let store = TestStore(initialState: FocusHomeFeature.State()) {
            FocusHomeFeature()
        }

        #expect(store.state == FocusHomeFeature.State())
    }
}
