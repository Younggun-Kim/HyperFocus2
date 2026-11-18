import ComposableArchitecture
import Testing
@testable import FocusTimer

@MainActor
struct FocusTimerFeatureTests {
    @Test func 끝까지_세면_부모에게_종료를_알린다() async {
        let clock = TestClock()
        let store = TestStore(initialState: FocusTimerFeature.State(duration: 2)) {
            FocusTimerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.startTapped) { $0.isRunning = true }
        await clock.advance(by: .seconds(1))
        await store.receive(\.tick) { $0.remainingSeconds = 1 }
        await clock.advance(by: .seconds(1))
        await store.receive(\.tick) {
            $0.remainingSeconds = 0
            $0.isRunning = false
        }
        await store.receive(\.delegate.sessionFinished)
    }

    @Test func 초기화하면_남은_시간이_처음으로_돌아간다() async {
        let clock = TestClock()
        let store = TestStore(initialState: FocusTimerFeature.State(duration: 10)) {
            FocusTimerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.startTapped) { $0.isRunning = true }
        await clock.advance(by: .seconds(1))
        await store.receive(\.tick) { $0.remainingSeconds = 9 }
        await store.send(.resetTapped) {
            $0.isRunning = false
            $0.remainingSeconds = 10
        }
    }
}
