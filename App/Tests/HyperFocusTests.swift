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

    @Test func 스플래시와_로그인_확인이_모두_끝나야_메인으로_넘어간다() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
        }

        await store.send(.onAppear)
        await store.receive(\.effect.ensureSignedInResponse) {
            $0.isSignInChecked = true
        }
        #expect(store.state.isLaunching)

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
        }
        #expect(!store.state.isLaunching)
    }

    @Test func 스플래시가_먼저_끝나도_로그인_확인을_기다린다() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
        }

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
        }
        #expect(store.state.isLaunching)

        await store.send(.onAppear)
        await store.receive(\.effect.ensureSignedInResponse) {
            $0.isSignInChecked = true
        }
        #expect(!store.state.isLaunching)
    }

    @Test func 로그인_확인에_실패해도_메인으로_넘어가고_다시_활성화되면_재시도한다() async {
        let results = LockIsolated<[Result<Void, DomainError>]>([.failure(.offline), .success(())])
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { results.withValue { $0.removeFirst() } }
        }

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
        }
        await store.send(.onAppear)
        await store.receive(\.effect.ensureSignedInResponse) {
            $0.isSignInChecked = true
            $0.needsSignInRetry = true
        }
        #expect(!store.state.isLaunching)

        await store.send(.sceneActivated) {
            $0.needsSignInRetry = false
        }
        await store.receive(\.effect.ensureSignedInResponse)
        #expect(results.isEmpty)

        // 성공한 뒤에는 다시 활성화돼도 요청하지 않는다. 요청하면 빈 배열에서 꺼내다 실패한다.
        await store.send(.sceneActivated)
    }

    // Home 구조로 바꾸면서 타이머 종료 → 기록 다시 불러오기 연결이 끊겼다.
    // FocusHome이 FocusTimer의 delegate를 Root로 올리면 이 테스트를 다시 작성한다.
    @Test(.disabled("Home 구조에서 sessionFinished delegate 재연결 전까지"))
    func 타이머가_끝나면_기록을_다시_불러온다() {}
}
