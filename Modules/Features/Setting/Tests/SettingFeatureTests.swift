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

    // MARK: - 조회

    @Test func 화면이_나타나면_저장된_설정을_불러온다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.fetchSettingUseCase.execute = { [stored] in .success(stored) }
        }

        await store.send(.onAppear)
        await store.receive(.settingLoaded(stored)) {
            $0.setting = self.stored
            $0.savedSetting = self.stored
        }
    }

    @Test func 불러오지_못하면_알림을_띄우고_기본값을_유지한다() async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.fetchSettingUseCase.execute = { .failure(.offline) }
        }

        await store.send(.onAppear)
        await store.receive(.settingLoadFailed(.offline)) {
            $0.destination = .alert(AlertState.settingFailure(.offline, action: .load)!)
        }
        #expect(store.state.setting == .default)
    }

    @Test(arguments: [DomainError.unauthorized, .notFound, .cancelled])
    func 인증_문제나_저장된_값이_없거나_취소되면_알리지_않는다(error: DomainError) async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.fetchSettingUseCase.execute = { .failure(error) }
        }

        await store.send(.onAppear)
        await store.receive(.settingLoadFailed(error))
    }

    // MARK: - 변경

    @Test func 토글하면_바로_바뀌고_전체_값을_저장한다() async {
        let saved = LockIsolated<AppSetting?>(nil)
        let store = TestStore(initialState: SettingFeature.State(setting: stored)) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { setting in
                saved.setValue(setting)
                return .success(setting)
            }
        }
        var expected = stored
        expected.hapticEnabled = true

        await store.send(.deviceSettingChanged(type: .haptic, isOn: true)) {
            $0.setting = expected
        }
        await store.receive(.settingSaved(expected)) {
            $0.savedSetting = expected
        }
        #expect(saved.value == expected)
    }

    @Test(arguments: SettingMenuType.DeviceSetting.allCases)
    func 각_항목은_자기_값만_바꾼다(type: SettingMenuType.DeviceSetting) async {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { .success($0) }
        }
        var expected = AppSetting.default
        expected[type] = true

        await store.send(.deviceSettingChanged(type: type, isOn: true)) {
            $0.setting = expected
        }
        await store.receive(.settingSaved(expected)) {
            $0.savedSetting = expected
        }
    }

    @Test func 같은_값이_다시_들어오면_저장하지_않는다() async {
        let store = TestStore(initialState: SettingFeature.State(setting: stored)) {
            SettingFeature()
        }

        await store.send(.deviceSettingChanged(type: .sound, isOn: true))
    }

    @Test func 저장에_실패하면_마지막으로_저장된_값으로_되돌린다() async {
        let store = TestStore(initialState: SettingFeature.State(setting: stored)) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { _ in .failure(.unknown) }
        }

        await store.send(.deviceSettingChanged(type: .alarm, isOn: false)) {
            $0.setting.alarmEnabled = false
        }
        await store.receive(.settingSaveFailed(.unknown)) {
            $0.setting = self.stored
            $0.destination = .alert(AlertState.settingFailure(.unknown, action: .save)!)
        }
    }

    @Test func 연달아_토글하면_마지막_값만_저장된다() async {
        let clock = TestClock()
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: {
            $0.updateSettingUseCase.execute = { setting in
                try? await clock.sleep(for: .seconds(1))
                return .success(setting)
            }
        }
        let soundOnly = AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: false)
        let both = AppSetting(soundEnabled: true, hapticEnabled: true, alarmEnabled: false)

        await store.send(.deviceSettingChanged(type: .sound, isOn: true)) {
            $0.setting = soundOnly
        }
        await store.send(.deviceSettingChanged(type: .haptic, isOn: true)) {
            $0.setting = both
        }
        await clock.advance(by: .seconds(1))
        await store.receive(.settingSaved(both)) {
            $0.savedSetting = both
        }
    }

    @Test func 조회_중에_토글하면_늦게_온_조회_결과가_덮어쓰지_않는다() async {
        let clock = TestClock()
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        } withDependencies: { [stored] in
            $0.fetchSettingUseCase.execute = {
                try? await clock.sleep(for: .seconds(1))
                return .success(stored)
            }
            $0.updateSettingUseCase.execute = { .success($0) }
        }
        let toggled = AppSetting(soundEnabled: false, hapticEnabled: false, alarmEnabled: true)

        await store.send(.onAppear)
        await store.send(.deviceSettingChanged(type: .alarm, isOn: true)) {
            $0.setting = toggled
        }
        await store.receive(.settingSaved(toggled)) {
            $0.savedSetting = toggled
        }
        await clock.advance(by: .seconds(1))
    }

    // MARK: - About Us

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
            $0.sendFeedbackUseCase.execute = { _, _ in .success(()) }
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
