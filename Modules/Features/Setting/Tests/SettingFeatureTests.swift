import ComposableArchitecture
import Testing
@testable import Setting

@MainActor
struct SettingFeatureTests {
    @Test func 화면이_나타나도_상태는_그대로다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.onAppear)
    }
}
