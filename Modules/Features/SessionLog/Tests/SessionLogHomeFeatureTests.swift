import ComposableArchitecture
import SessionLog
import Testing

@MainActor
struct SessionLogHomeFeatureTests {
    @Test func 초기_상태로_만들어진다() {
        let store = TestStore(initialState: SessionLogHomeFeature.State()) {
            SessionLogHomeFeature()
        }

        #expect(store.state == SessionLogHomeFeature.State())
    }

    @Test func 설정_버튼을_누르면_settingTapped_delegate를_보낸다() async {
        let store = TestStore(initialState: SessionLogHomeFeature.State()) {
            SessionLogHomeFeature()
        }

        await store.send(.settingButtonTapped)
        await store.receive(\.delegate.settingTapped)
    }
}
