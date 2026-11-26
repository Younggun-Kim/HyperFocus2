import ComposableArchitecture
import Testing
@testable import Splash

@MainActor
struct SplashFeatureTests {
    @Test func 일_초마다_단계를_넘기고_끝나면_finished_delegate를_보낸다() async {
        let clock = TestClock()
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.onAppear)

        await clock.advance(by: .seconds(1))
        await store.receive(\.phaseChanged) {
            $0.phase = .blurring
        }

        await clock.advance(by: .seconds(1))
        await store.receive(\.phaseChanged) {
            $0.phase = .title
        }

        await clock.advance(by: .seconds(1))
        await store.receive(\.delegate.finished)
    }

    @Test func 다시_나타나면_연출을_처음부터_다시_한다() async {
        let clock = TestClock()
        var state = SplashFeature.State()
        state.phase = .blurring
        let store = TestStore(initialState: state) {
            SplashFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.onAppear) {
            $0.phase = .light
        }
        await clock.advance(by: .milliseconds(500))

        // 진행 중이던 타이머는 취소된다. 남아 있었다면 0.5초 뒤에 단계가 넘어간다.
        await store.send(.onAppear)
        await clock.advance(by: .milliseconds(500))

        await clock.advance(by: .milliseconds(500))
        await store.receive(\.phaseChanged) {
            $0.phase = .blurring
        }

        await clock.advance(by: .seconds(2))
        await store.receive(\.phaseChanged) {
            $0.phase = .title
        }
        await store.receive(\.delegate.finished)
    }
}
