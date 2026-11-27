import ComposableArchitecture
import Domain
import FocusTimer
import SessionLog
import Setting
import Testing
@testable import HyperFocus

@MainActor
struct RootFeatureTests {
    @Test func 초기_상태는_두_홈_화면을_가진다() {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }

        #expect(store.state.timer == FocusHomeFeature.State())
        #expect(store.state.log == SessionLogHomeFeature.State())
        #expect(store.state.logPath.isEmpty)
    }

    @Test func 기록_화면에서_설정을_누르면_설정_화면이_쌓인다() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }

        await store.send(\.log.settingButtonTapped)
        await store.receive(\.log.delegate.settingTapped) {
            $0.logPath[id: 0] = .setting(SettingFeature.State())
        }
    }

    @Test func 설정_화면에서_뒤로_가면_스택이_비워진다() async {
        var state = RootFeature.State()
        state.logPath.append(.setting(SettingFeature.State()))
        let store = TestStore(initialState: state) {
            RootFeature()
        }

        await store.send(\.logPath.popFrom, 0) {
            $0.logPath = StackState()
        }
    }

    // MARK: - 시작 흐름

    @Test func 스플래시와_시작_확인이_모두_끝나야_메인으로_넘어간다() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
            $0.fetchProfileUseCase.execute = { .success(.mock) }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.isSignInChecked = true
            $0.$profile.withLock { $0 = .mock }
        }
        #expect(store.state.isLaunching)

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
        }
        #expect(!store.state.isLaunching)
    }

    @Test func 스플래시가_먼저_끝나도_시작_확인을_기다린다() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
            $0.fetchProfileUseCase.execute = { .success(.mock) }
        }

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
        }
        #expect(store.state.isLaunching)

        await store.send(.view(.onAppear))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.isSignInChecked = true
            $0.$profile.withLock { $0 = .mock }
        }
        #expect(!store.state.isLaunching)
    }

    @Test func 로그인_확인에_실패하면_프로필을_부르지_않고_다시_활성화되면_재시도한다() async {
        let results = LockIsolated<[Result<Void, DomainError>]>([.failure(.offline), .success(())])
        let fetchCount = LockIsolated(0)
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { results.withValue { $0.removeFirst() } }
            $0.fetchProfileUseCase.execute = {
                fetchCount.withValue { $0 += 1 }
                return .success(.mock)
            }
        }

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
        }
        await store.send(.view(.onAppear))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.isSignInChecked = true
            $0.needsSignInRetry = true
        }
        #expect(!store.state.isLaunching)
        #expect(fetchCount.value == 0)

        await store.send(.view(.sceneActivated)) {
            $0.needsSignInRetry = false
        }
        await store.receive(\.effect.fetchProfileResponse) {
            $0.$profile.withLock { $0 = .mock }
        }
        #expect(results.isEmpty)
        #expect(fetchCount.value == 1)

        // 성공한 뒤에는 다시 활성화돼도 요청하지 않는다. 요청하면 빈 배열에서 꺼내다 실패한다.
        await store.send(.view(.sceneActivated))
    }

    @Test func 프로필_조회에_실패해도_메인으로_넘어가고_다시_활성화되면_재시도한다() async {
        let results = LockIsolated<[Result<Profile, DomainError>]>([.failure(.offline), .success(.mock)])
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
            $0.fetchProfileUseCase.execute = { results.withValue { $0.removeFirst() } }
        }

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
        }
        await store.send(.view(.onAppear))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.isSignInChecked = true
            $0.needsSignInRetry = true
        }
        #expect(!store.state.isLaunching)
        #expect(store.state.profile == nil)

        await store.send(.view(.sceneActivated)) {
            $0.needsSignInRetry = false
        }
        await store.receive(\.effect.fetchProfileResponse) {
            $0.$profile.withLock { $0 = .mock }
        }
    }

    // MARK: - 프로필 공유

    @Test func 설정_화면은_Root의_프로필을_함께_본다() async {
        var state = RootFeature.State()
        state.isSignInChecked = true
        state.logPath.append(.setting(SettingFeature.State(profile: state.$profile)))
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.fetchProfileUseCase.execute = { .success(.mock) }
        }

        // 설정 화면에서 Apple 로그인에 성공하면 Root가 프로필을 다시 불러온다.
        await store.send(.logPath(.element(id: 0, action: .setting(.delegate(.accountChanged)))))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.$profile.withLock { $0 = .mock }
        }
        #expect(store.state.logPath[id: 0] == .setting(SettingFeature.State(profile: Shared(value: .mock))))
    }

    // MARK: - 로그아웃

    @Test func 탭을_고르면_선택된_탭이_바뀐다() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }

        await store.send(.view(.tabSelected(.log))) {
            $0.selectedTab = .log
        }
    }

    @Test func 로그아웃하면_타이머_탭으로_돌아가고_익명_계정을_다시_받는다() async {
        var state = RootFeature.State()
        state.isSignInChecked = true
        state.selectedTab = .log
        state.$profile.withLock { $0 = .mock }
        state.logPath.append(.setting(SettingFeature.State(profile: state.$profile)))
        let signedIn = LockIsolated(false)
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = {
                signedIn.setValue(true)
                return .success(())
            }
            $0.fetchProfileUseCase.execute = { .success(.mock) }
        }

        await store.send(.logPath(.element(id: 0, action: .setting(.delegate(.logout))))) {
            $0.$profile.withLock { $0 = nil }
            $0.logPath = StackState()
            $0.selectedTab = .timer
        }
        await store.receive(\.effect.fetchProfileResponse) {
            $0.$profile.withLock { $0 = .mock }
        }
        #expect(signedIn.value)
    }

    // Home 구조로 바꾸면서 타이머 종료 → 기록 다시 불러오기 연결이 끊겼다.
    // FocusHome이 FocusTimer의 delegate를 Root로 올리면 이 테스트를 다시 작성한다.
    @Test(.disabled("Home 구조에서 sessionFinished delegate 재연결 전까지"))
    func 타이머가_끝나면_기록을_다시_불러온다() {}
}
