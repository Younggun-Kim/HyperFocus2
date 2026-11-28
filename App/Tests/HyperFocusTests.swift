import ComposableArchitecture
import Domain
import FocusTimer
import Foundation
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

        await store.send(.log(.view(.settingTapped)))
        await store.receive(\.log.delegate.settingTapped) {
            $0.logPath[id: 0] = .setting(SettingFeature.State())
        }
    }

    @Test func 빈_기록_화면에서_시작을_누르면_타이머_탭으로_옮긴다() async {
        var state = RootFeature.State()
        state.selectedTab = .log
        let store = TestStore(initialState: state) {
            RootFeature()
        }

        await store.send(.log(.view(.startTapped)))
        await store.receive(\.log.delegate.startFocusTapped) {
            $0.selectedTab = .timer
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
        let store = TestStore(initialState: .updateChecked) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
            $0.ignoreAccountPrefetch()
            $0.fetchProfileUseCase.execute = { .success(.mock) }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.isSignInChecked = true
            $0.$profile.withLock { $0 = .mock }
        }
        await store.receiveLogPrefetch()
        #expect(store.state.isLaunching)

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
        }
        #expect(!store.state.isLaunching)
    }

    @Test func 스플래시가_먼저_끝나도_시작_확인을_기다린다() async {
        let store = TestStore(initialState: .updateChecked) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
            $0.ignoreAccountPrefetch()
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
        await store.receiveLogPrefetch()
        #expect(!store.state.isLaunching)
    }

    @Test func 로그인_확인에_실패하면_프로필을_부르지_않고_다시_활성화되면_재시도한다() async {
        let results = LockIsolated<[Result<Void, DomainError>]>([.failure(.offline), .success(())])
        let fetchCount = LockIsolated(0)
        let store = TestStore(initialState: .updateChecked) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { results.withValue { $0.removeFirst() } }
            $0.ignoreAccountPrefetch()
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
        await store.receiveLogPrefetch()
        #expect(results.isEmpty)
        #expect(fetchCount.value == 1)

        // 성공한 뒤에는 다시 활성화돼도 로그인을 요청하지 않는다. 요청하면 빈 배열에서 꺼내다 실패한다.
        await store.send(.view(.sceneActivated))
    }

    @Test func 프로필_조회에_실패해도_메인으로_넘어가고_다시_활성화되면_재시도한다() async {
        let results = LockIsolated<[Result<Profile, DomainError>]>([.failure(.offline), .success(.mock)])
        let store = TestStore(initialState: .updateChecked) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
            $0.ignoreAccountPrefetch()
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
        await store.receiveLogPrefetch()
    }

    @Test func 프로필을_받으면_기록_요약을_미리_받는다() async {
        let fetchCount = LockIsolated(0)
        let store = TestStore(initialState: .updateChecked) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
            $0.fetchProfileUseCase.execute = { .success(.mock) }
            $0.fetchSessionLogDashboardUseCase.execute = {
                fetchCount.withValue { $0 += 1 }
                return .failure(.cancelled)
            }
            $0.syncSettingUseCase.execute = { _ in .success(.default) }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.isSignInChecked = true
            $0.$profile.withLock { $0 = .mock }
        }
        await store.receiveLogPrefetch()
        // 기록 탭을 열지 않았는데도 요청이 나갔다.
        #expect(fetchCount.value == 1)
    }

    // MARK: - 설정 동기화

    @Test func 프로필을_받으면_그_계정의_설정을_서버와_맞춘다() async {
        let synced = LockIsolated<[String]>([])
        let store = TestStore(initialState: .updateChecked) {
            RootFeature()
        } withDependencies: {
            $0.ensureSignedInUseCase.execute = { .success(()) }
            $0.fetchProfileUseCase.execute = { .success(.mock) }
            $0.ignoreAccountPrefetch()
            $0.syncSettingUseCase.execute = { accountId in
                synced.withValue { $0.append(accountId) }
                return .success(.default)
            }
        }

        await store.send(.view(.onAppear))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.isSignInChecked = true
            $0.$profile.withLock { $0 = .mock }
        }
        await store.receiveLogPrefetch()
        #expect(synced.value == [Profile.mock.userId])
    }

    @Test func 로그인된_채로_다시_활성화되면_설정을_다시_맞춘다() async {
        let synced = LockIsolated<[String]>([])
        var state = RootFeature.State.updateChecked
        state.$profile.withLock { $0 = .mock }
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.syncSettingUseCase.execute = { accountId in
                synced.withValue { $0.append(accountId) }
                return .failure(.offline)
            }
        }

        await store.send(.view(.sceneActivated))
        // 실패해도 화면 상태는 그대로다. 다음 활성화 때 다시 맞춘다.
        await store.send(.view(.sceneActivated))
        #expect(synced.value == [Profile.mock.userId, Profile.mock.userId])
    }

    @Test func 계정이_없으면_다시_활성화돼도_설정을_맞추지_않는다() async {
        let store = TestStore(initialState: .updateChecked) {
            RootFeature()
        }

        // syncSettingUseCase를 부르면 testValue가 실패를 보고한다.
        await store.send(.view(.sceneActivated))
    }

    // MARK: - 프로필 공유

    @Test func 설정_화면은_Root의_프로필을_함께_본다() async {
        var state = RootFeature.State()
        state.isSignInChecked = true
        state.logPath.append(.setting(SettingFeature.State(profile: state.$profile)))
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.ignoreAccountPrefetch()
            $0.fetchProfileUseCase.execute = { .success(.mock) }
        }

        // 설정 화면이 새 프로필을 받아 오면 Root가 그대로 넣고, 설정 화면에도 함께 보인다.
        await store.send(.logPath(.element(id: 0, action: .setting(.delegate(.accountChanged(Profile.mock)))))) {
            $0.$profile.withLock { $0 = .mock }
        }
        await store.receiveLogPrefetch()
        #expect(store.state.logPath[id: 0] == .setting(SettingFeature.State(profile: Shared(value: .mock))))
    }

    @Test func 설정_화면이_새_프로필을_받지_못하면_Root가_다시_불러온다() async {
        var state = RootFeature.State.updateChecked
        state.isSignInChecked = true
        state.logPath.append(.setting(SettingFeature.State(profile: state.$profile)))
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.ignoreAccountPrefetch()
            $0.fetchProfileUseCase.execute = { .success(.mock) }
        }

        await store.send(.logPath(.element(id: 0, action: .setting(.delegate(.accountChanged(nil))))))
        await store.receive(\.effect.fetchProfileResponse) {
            $0.$profile.withLock { $0 = .mock }
        }
        await store.receiveLogPrefetch()
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
            $0.ignoreAccountPrefetch()
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
        await store.receiveLogPrefetch()
        #expect(signedIn.value)
    }

    // MARK: - 세션 만료

    @Test func 세션이_만료되면_로그아웃처럼_타이머_탭으로_돌아가고_익명_계정을_다시_받는다() async {
        var state = RootFeature.State.updateChecked
        state.isSplashFinished = true
        state.isSignInChecked = true
        state.selectedTab = .log
        state.$profile.withLock { $0 = .mock }
        state.logPath.append(.setting(SettingFeature.State(profile: state.$profile)))
        let (events, expire) = AsyncStream<Void>.makeStream()
        // 다시 로그인하는 일을 붙잡아 둔다. `profile`은 참조로 공유돼서, 만료를 검증하기 전에
        // 새 프로필까지 들어오면 계정이 비워진 순간을 볼 수 없다.
        let (signInGate, allowSignIn) = AsyncStream<Void>.makeStream()
        let signedIn = LockIsolated(false)
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.observeSessionExpiredUseCase.execute = { events }
            $0.checkAppUpdateUseCase.execute = { .success(.upToDate) }
            $0.ensureSignedInUseCase.execute = {
                signedIn.setValue(true)
                for await _ in signInGate { break }
                return .success(())
            }
            $0.ignoreAccountPrefetch()
            $0.fetchProfileUseCase.execute = { .success(.mock) }
        }

        let task = await store.send(.view(.task))
        // 업데이트 확인은 기다릴 것이 없어 먼저 끝난다. 받은 뒤에 만료를 보내 순서를 고정한다.
        await store.receive(\.effect.checkAppUpdateResponse)
        expire.yield()
        await store.receive(\.effect.sessionExpired) {
            $0.$profile.withLock { $0 = nil }
            $0.logPath = StackState()
            $0.selectedTab = .timer
        }
        allowSignIn.yield()
        await store.receive(\.effect.fetchProfileResponse) {
            $0.$profile.withLock { $0 = .mock }
        }
        await store.receiveLogPrefetch()
        #expect(signedIn.value)

        // 화면이 사라지면 구독도 끝난다.
        await task.cancel()
    }

    // MARK: - 업데이트 확인

    @Test func 업데이트가_없으면_확인이_끝난다() async {
        let store = updateStore(.success(.upToDate))

        await store.send(.view(.task))
        await store.receive(\.effect.checkAppUpdateResponse) {
            $0.isUpdateChecked = true
        }
    }

    @Test func 업데이트_확인에_실패해도_막지_않는다() async {
        let store = updateStore(.failure(.offline))

        await store.send(.view(.task))
        await store.receive(\.effect.checkAppUpdateResponse) {
            $0.isUpdateChecked = true
        }
    }

    @Test func 스플래시_연출이_끝난_뒤에_업데이트_알림을_띄운다() async {
        let update = AppUpdate(policy: .optional)
        let store = updateStore(.success(update))

        await store.send(.view(.task))
        await store.receive(\.effect.checkAppUpdateResponse) {
            $0.pendingUpdate = update
        }
        #expect(store.state.alert == nil)

        await store.send(.splash(.delegate(.finished))) {
            $0.isSplashFinished = true
            $0.alert = .optionalUpdate
        }
    }

    @Test func 스플래시가_먼저_끝났으면_응답이_오자마자_알림을_띄운다() async {
        var state = RootFeature.State()
        state.isSplashFinished = true
        let update = AppUpdate(policy: .required)
        let store = updateStore(.success(update), state: state)

        await store.send(.view(.task))
        await store.receive(\.effect.checkAppUpdateResponse) {
            $0.pendingUpdate = update
            $0.alert = .requiredUpdate
        }
    }

    @Test func 권장_업데이트를_미루면_지금_버전으로_들어간다() async {
        let store = updateStore(.success(.upToDate), state: alerted(AppUpdate(policy: .optional)))

        await store.send(.alert(.presented(.laterTapped))) {
            $0.alert = nil
            $0.isUpdateChecked = true
        }
        #expect(!store.state.isLaunching)
    }

    @Test func 권장_업데이트를_누르면_스토어를_열고_들어간다() async {
        let storeURL = URL(string: "https://apps.apple.com/app/id1")!
        let opened = LockIsolated<URL?>(nil)
        let store = updateStore(.success(.upToDate), state: alerted(AppUpdate(policy: .optional, storeURL: storeURL))) {
            opened.setValue($0)
        }

        await store.send(.alert(.presented(.updateTapped))) {
            $0.alert = nil
            $0.isUpdateChecked = true
        }
        #expect(opened.value == storeURL)
    }

    @Test func 강제_업데이트는_스토어를_열어도_알림이_다시_떠서_들어갈_수_없다() async {
        let opened = LockIsolated<URL?>(nil)
        let store = updateStore(.success(.upToDate), state: alerted(AppUpdate(policy: .required))) {
            opened.setValue($0)
        }

        // 같은 알림을 새로 띄우므로 상태로는 바뀐 것이 없다.
        await store.send(.alert(.presented(.updateTapped)))
        #expect(store.state.alert == .requiredUpdate)
        #expect(store.state.isLaunching)
        // 서버가 주소를 주지 않으면 기본 App Store 주소를 연다.
        #expect(opened.value == RootFeature.appStoreURL)
    }

    // Home 구조로 바꾸면서 타이머 종료 → 기록 다시 불러오기 연결이 끊겼다.
    // FocusHome이 FocusTimer의 delegate를 Root로 올리면 이 테스트를 다시 작성한다.
    @Test(.disabled("Home 구조에서 sessionFinished delegate 재연결 전까지"))
    func 타이머가_끝나면_기록을_다시_불러온다() {}
}

// MARK: - Helpers

private extension DependencyValues {
    /// 기록 요약을 미리 받는 요청이 상태를 바꾸지 않게 한다. 프로필 흐름을 보는 테스트에서 쓴다.
    /// 계정이 정해진 뒤 미리 받는 기록 요약과 설정 동기화를 아무 일 없이 끝낸다.
    mutating func ignoreAccountPrefetch() {
        fetchSessionLogDashboardUseCase.execute = { .failure(.cancelled) }
        syncSettingUseCase.execute = { _ in .success(.default) }
    }
}

@MainActor
private extension TestStore where State == RootFeature.State, Action == RootFeature.Action {
    /// 프로필을 받은 뒤 기록 요약을 미리 받는 흐름. `ignoreAccountPrefetch()`와 함께 쓴다.
    func receiveLogPrefetch() async {
        await receive(\.log.prefetch)
        await receive(\.log.effect.dashboardResponse)
    }
}

private extension RootFeature.State {
    /// 업데이트 확인을 마친 상태. 시작 흐름 테스트가 로그인 확인만 보게 한다.
    static var updateChecked: Self {
        var state = Self()
        state.isUpdateChecked = true
        return state
    }
}

/// 스플래시가 끝나 업데이트 알림이 떠 있는 상태.
private func alerted(_ update: AppUpdate) -> RootFeature.State {
    var state = RootFeature.State()
    state.isSplashFinished = true
    state.isSignInChecked = true
    state.pendingUpdate = update
    state.alert = update.policy == .required ? .requiredUpdate : .optionalUpdate
    return state
}

/// 업데이트 확인 결과를 정해 둔 Store. 세션 만료 구독은 바로 끝나게 한다.
@MainActor
private func updateStore(
    _ result: Result<AppUpdate, DomainError>,
    state: RootFeature.State = RootFeature.State(),
    onOpenURL: @escaping @Sendable (URL) -> Void = { _ in }
) -> TestStoreOf<RootFeature> {
    TestStore(initialState: state) {
        RootFeature()
    } withDependencies: {
        $0.checkAppUpdateUseCase.execute = { result }
        $0.observeSessionExpiredUseCase.execute = { AsyncStream { $0.finish() } }
        $0.openURL = OpenURLEffect { url in
            onOpenURL(url)
            return true
        }
    }
}
