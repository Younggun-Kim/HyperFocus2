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

    @Test(arguments: [SettingMenuType.AboutUs.privacyPolicy, .termsOfService])
    func 문서_항목을_누르면_웹_페이지_시트를_띄운다(item: SettingMenuType.AboutUs) async throws {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }
        let url = try #require(item.url)

        await store.send(.aboutUsTapped(item)) {
            $0.destination = .webPage(url)
        }
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }
    }

    @Test func Talk_to_Developer를_누르면_피드백_시트를_띄운다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.aboutUsTapped(.talkToDeveloper)) {
            $0.destination = .feedback(FeedbackFeature.State())
        }
    }

    @Test func 피드백_전송에_성공하면_시트를_닫는다() async {
        var state = SettingFeature.State()
        state.destination = .feedback(FeedbackFeature.State(text: "좋아요"))
        let store = TestStore(initialState: state) {
            SettingFeature()
        } withDependencies: {
            $0.sendFeedbackUseCase.execute = { _, _ in }
        }

        await store.send(.destination(.presented(.feedback(.sendTapped)))) {
            $0.destination?.modify(\.feedback) { $0.isSending = true }
        }
        await store.receive(.destination(.presented(.feedback(.sendSucceeded)))) {
            $0.destination?.modify(\.feedback) { $0.isSending = false }
        }
        await store.receive(.destination(.presented(.feedback(.delegate(.sent))))) {
            $0.destination = nil
        }
    }
}
