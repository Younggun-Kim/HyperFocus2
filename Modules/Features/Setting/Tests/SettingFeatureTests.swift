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

    @Test func 기기_설정을_켜면_해당_항목만_켜진다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.deviceSettingChanged(type: .sound, isOn: true)) {
            $0.soundOn = true
        }
        await store.send(.deviceSettingChanged(type: .haptic, isOn: true)) {
            $0.hapticOn = true
        }
        await store.send(.deviceSettingChanged(type: .alarm, isOn: true)) {
            $0.alarmOn = true
        }
    }

    @Test func 기기_설정을_끄면_해당_항목만_꺼진다() async {
        let store = TestStore(
            initialState: SettingFeature.State(soundOn: true, hapticOn: true, alarmOn: true)
        ) {
            SettingFeature()
        }

        await store.send(.deviceSettingChanged(type: .haptic, isOn: false)) {
            $0.hapticOn = false
        }
    }

    @Test func 같은_값이_다시_들어와도_상태는_그대로다() async {
        let store = TestStore(initialState: SettingFeature.State(soundOn: true)) {
            SettingFeature()
        }

        await store.send(.deviceSettingChanged(type: .sound, isOn: true))
    }

    @Test(arguments: SettingMenuType.AboutUs.allCases)
    func About_Us_항목을_누르면_부모에게_알린다(item: SettingMenuType.AboutUs) async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.aboutUsTapped(item))
        await store.receive(.delegate(.aboutUsSelected(item)))
    }
}
