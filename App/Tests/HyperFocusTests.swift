import ComposableArchitecture
import Domain
import Testing
@testable import HyperFocus

@MainActor
struct RootFeatureTests {
    @Test func 타이머가_끝나면_기록을_다시_불러온다() async {
        let samples = [Sample(id: "finished")]
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.fetchSamplesUseCase.execute = { samples }
        }

        await store.send(.timer(.delegate(.sessionFinished(seconds: 1500))))
        await store.receive(\.history.reload)
        await store.receive(\.history.samplesResponse.success) {
            $0.history.samples = samples
        }
    }
}
