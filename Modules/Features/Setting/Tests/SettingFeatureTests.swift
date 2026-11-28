import ComposableArchitecture
import Domain
import Foundation
import Testing
@testable import Setting

@MainActor
struct SettingFeatureTests {
    private let stored = AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: true)

    // MARK: - 계정

    @Test func 프로필이_없거나_익명이면_email이_없다() {
        #expect(SettingFeature.State().email == nil)

        let anonymous = Profile(
            userId: "test-user", email: "", name: "", profileImageUrl: nil, provider: .anonymous,
            role: "USER", status: "ACTIVE", lastLoginAt: .distantPast, createdAt: .distantPast,
            profileImageUrlOptional: nil
        )
        #expect(SettingFeature.State(profile: Shared(value: anonymous)).email == nil)
    }

    @Test func 넘겨받은_프로필이_바뀌면_email도_따라_바뀐다() {
        let profile = Shared<Profile?>(value: nil)
        let state = SettingFeature.State(profile: profile)
        #expect(state.email == nil)

        profile.withLock { $0 = .mock }
        #expect(state.email == Profile.mock.email)
    }

    // MARK: - 구독

    @Test func 화면이_보이는_동안_저장된_설정을_따라간다() async {
        let (stream, continuation) = AsyncStream<AppSetting>.makeStream()
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.observeSettingUseCase.execute = { stream }
        }
        let synced = AppSetting(soundEnabled: false, hapticEnabled: true, alarmEnabled: false)

        let task = await store.send(.view(.task))
        continuation.yield(stored)
        await store.receive(\.effect.settingChanged, stored) {
            $0.setting = self.stored
        }
        // 다른 곳(동기화)에서 바뀐 값도 따라간다.
        continuation.yield(synced)
        await store.receive(\.effect.settingChanged, synced) {
            $0.setting = synced
        }
        await task.cancel()
    }

    // MARK: - 변경

    @Test func 토글하면_바로_바뀌고_전체_값을_저장한다() async {
        let saved = LockIsolated<AppSetting?>(nil)
        let store = TestStore(initialState: SettingFeature.State(setting: stored)) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { setting in
                saved.setValue(setting)
                return .success(())
            }
        }
        var expected = stored
        expected.hapticEnabled = true

        await store.send(.view(.deviceSettingChanged(type: .haptic, isOn: true))) {
            $0.setting = expected
        }
        await store.receive(\.effect.updateSettingResponse)
        #expect(saved.value == expected)
    }

    @Test(arguments: SettingMenuType.DeviceSetting.allCases)
    func 각_항목은_자기_값만_바꾼다(type: SettingMenuType.DeviceSetting) async {
        let saved = LockIsolated<AppSetting?>(nil)
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { setting in
                saved.setValue(setting)
                return .success(())
            }
        }
        var expected = AppSetting.default
        expected[type] = true

        await store.send(.view(.deviceSettingChanged(type: type, isOn: true))) {
            $0.setting = expected
        }
        await store.receive(\.effect.updateSettingResponse)
        #expect(saved.value == expected)
    }

    @Test func 같은_값이_다시_들어오면_저장하지_않는다() async {
        let store = TestStore(initialState: SettingFeature.State(setting: stored)) {
            SettingFeature()
        }

        await store.send(.view(.deviceSettingChanged(type: .sound, isOn: true)))
    }

    @Test func 연달아_토글하면_값마다_저장한다() async {
        let saved = LockIsolated<[AppSetting]>([])
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { setting in
                saved.withValue { $0.append(setting) }
                return .success(())
            }
        }
        let soundOnly = AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: false)
        let both = AppSetting(soundEnabled: true, hapticEnabled: true, alarmEnabled: false)

        await store.send(.view(.deviceSettingChanged(type: .sound, isOn: true))) {
            $0.setting = soundOnly
        }
        await store.receive(\.effect.updateSettingResponse)
        await store.send(.view(.deviceSettingChanged(type: .haptic, isOn: true))) {
            $0.setting = both
        }
        await store.receive(\.effect.updateSettingResponse)
        #expect(saved.value == [soundOnly, both])
    }

    @Test func 저장에_실패하면_알림을_띄운다() async {
        let store = TestStore(initialState: SettingFeature.State(setting: stored)) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { _ in .failure(.unknown) }
        }

        await store.send(.view(.deviceSettingChanged(type: .alarm, isOn: false))) {
            $0.setting.alarmEnabled = false
        }
        await store.receive(\.effect.updateSettingResponse) {
            $0.destination = .alert(AlertState.settingSaveFailure(.unknown)!)
        }
    }

    @Test(arguments: [DomainError.unauthorized, .notFound, .cancelled])
    func 인증_문제나_대상이_없거나_취소되면_저장_실패를_알리지_않는다(error: DomainError) async {
        let store = TestStore(initialState: SettingFeature.State(setting: stored)) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { _ in .failure(error) }
        }

        await store.send(.view(.deviceSettingChanged(type: .alarm, isOn: false))) {
            $0.setting.alarmEnabled = false
        }
        await store.receive(\.effect.updateSettingResponse)
    }

    // MARK: - About Us

    @Test(arguments: [SettingMenuType.AboutUs.privacyPolicy, .termsOfService])
    func 문서_항목을_누르면_웹_페이지_시트를_띄운다(item: SettingMenuType.AboutUs) async throws {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }
        let url = try #require(item.url)

        await store.send(.view(.aboutUsTapped(item))) {
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

        await store.send(.view(.aboutUsTapped(.talkToDeveloper))) {
            $0.destination = .feedback(FeedbackFeature.State())
        }
    }

    @Test func 피드백_전송에_성공하면_시트를_닫고_토스트를_띄운다() async {
        var state = SettingFeature.State()
        state.destination = .feedback(FeedbackFeature.State(text: "좋아요"))
        let store = TestStore(initialState: state) {
            SettingFeature()
        } withDependencies: {
            $0.sendFeedbackUseCase.execute = { _, _ in .success(()) }
        }

        await store.send(.destination(.presented(.feedback(.view(.sendTapped))))) {
            $0.destination?.modify(\.feedback) { $0.isSending = true }
        }
        await store.receive(\.destination.feedback.effect.sendResponse) {
            $0.destination?.modify(\.feedback) { $0.isSending = false }
        }
        await store.receive(\.destination.feedback.delegate, .sent) {
            $0.destination = nil
            $0.toast = "Message received! Thanks. 💌"
        }
    }

    @Test func 토스트가_사라지면_문구를_지운다() async {
        var state = SettingFeature.State()
        state.toast = "Message received! Thanks. 💌"
        let store = TestStore(initialState: state) {
            SettingFeature()
        }

        await store.send(.view(.toastDismissed)) {
            $0.toast = nil
        }
    }

    // MARK: - 로그아웃

    @Test(arguments: [true, false])
    func 로그아웃을_누르면_요청_결과와_상관없이_로그아웃을_알린다(succeeds: Bool) async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.logoutUseCase.execute = { succeeds ? .success(()) : .failure(.offline) }
        }

        await store.send(.view(.logoutTapped))
        await store.receive(\.delegate.logout)
    }

    // MARK: - 탈퇴

    @Test func 탈퇴를_누르면_확인_알림을_띄운다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }

        await store.send(.view(.withdrawalTapped)) {
            $0.destination = .alert(.withdrawalConfirm)
        }
    }

    @Test func 확인_알림의_삭제_버튼만_탈퇴_액션을_보낸다() throws {
        let buttons = AlertState<SettingFeature.Alert>.withdrawalConfirm.buttons
        try #require(buttons.count == 2)

        func sentAction(_ button: ButtonState<SettingFeature.Alert>) -> SettingFeature.Alert? {
            var sent: SettingFeature.Alert?
            button.withAction { sent = $0 }
            return sent
        }

        let delete = try #require(buttons.first { $0.role == .destructive })
        #expect(sentAction(delete) == .confirmWithdrawal)

        let keep = try #require(buttons.first { $0.role == .cancel })
        #expect(sentAction(keep) == nil)
    }

    @Test func 확인_알림에서_삭제를_누르면_탈퇴하고_로그아웃을_알린다() async {
        let called = LockIsolated(false)
        var state = SettingFeature.State()
        state.destination = .alert(.withdrawalConfirm)
        let store = TestStore(initialState: state) {
            SettingFeature()
        } withDependencies: {
            $0.withdrawUseCase.execute = {
                called.setValue(true)
                return .success(())
            }
        }

        await store.send(.destination(.presented(.alert(.confirmWithdrawal)))) {
            $0.destination = nil
        }
        await store.receive(\.effect.withdrawResponse)
        await store.receive(\.delegate.logout)
        #expect(called.value)
    }

    @Test func 탈퇴에_실패하면_알리고_로그인_상태를_유지한다() async throws {
        let alert = try #require(AlertState<SettingFeature.Alert>.withdrawalFailure(.offline))
        var state = SettingFeature.State()
        state.destination = .alert(.withdrawalConfirm)
        let store = TestStore(initialState: state) {
            SettingFeature()
        } withDependencies: {
            $0.withdrawUseCase.execute = { .failure(.offline) }
        }

        await store.send(.destination(.presented(.alert(.confirmWithdrawal)))) {
            $0.destination = nil
        }
        await store.receive(\.effect.withdrawResponse) {
            $0.destination = .alert(alert)
        }
    }

    /// 취소는 흐름이고, 세션 만료는 앱 전역에서 처리한다.
    @Test(arguments: [DomainError.cancelled, .unauthorized])
    func 알리지_않는_에러로_탈퇴에_실패하면_조용히_넘긴다(error: DomainError) async {
        var state = SettingFeature.State()
        state.destination = .alert(.withdrawalConfirm)
        let store = TestStore(initialState: state) {
            SettingFeature()
        } withDependencies: {
            $0.withdrawUseCase.execute = { .failure(error) }
        }

        await store.send(.destination(.presented(.alert(.confirmWithdrawal)))) {
            $0.destination = nil
        }
        await store.receive(\.effect.withdrawResponse)
    }

    @Test func 확인_알림에서_취소하면_탈퇴하지_않는다() async {
        var state = SettingFeature.State()
        state.destination = .alert(.withdrawalConfirm)
        let store = TestStore(initialState: state) {
            SettingFeature()
        }

        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }
    }
}
