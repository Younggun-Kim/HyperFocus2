import ComposableArchitecture
import Data
import Testing
@testable import SessionHistory

@MainActor
struct SessionHistoryFeatureTests {
    @Test func 화면이_나타나면_기록을_불러온다() async {
        let samples = [Sample(id: "a"), Sample(id: "b")]
        let store = TestStore(initialState: SessionHistoryFeature.State()) {
            SessionHistoryFeature()
        } withDependencies: {
            $0.sampleClient.getSamples = { samples }
        }

        await store.send(.onAppear)
        await store.receive(\.samplesResponse.success) { $0.samples = samples }
    }

    @Test func 불러오기에_실패하면_에러_메시지를_보여준다() async {
        struct Failure: Error {}
        let store = TestStore(initialState: SessionHistoryFeature.State()) {
            SessionHistoryFeature()
        } withDependencies: {
            $0.sampleClient.getSamples = { throw Failure() }
        }

        await store.send(.onAppear)
        await store.receive(\.samplesResponse.failure) {
            $0.errorMessage = "\(Failure())"
        }
    }
}
