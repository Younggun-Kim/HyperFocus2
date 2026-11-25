import ComposableArchitecture
import Domain
import Testing
@testable import Setting

@MainActor
struct FeedbackFeatureTests {
    private struct SendError: Error {}

    @Test func 카테고리를_누르면_선택이_바뀐다() async {
        let store = TestStore(initialState: FeedbackFeature.State()) {
            FeedbackFeature()
        }

        await store.send(.categoryTapped(.bugReport)) {
            $0.category = .bugReport
        }
    }

    @Test func 입력은_500자까지만_받는다() async {
        let store = TestStore(initialState: FeedbackFeature.State()) {
            FeedbackFeature()
        }
        let longText = String(repeating: "a", count: 501)

        await store.send(.textChanged(longText)) {
            $0.text = String(repeating: "a", count: 500)
        }
    }

    @Test(arguments: ["", "   ", "\n\n"])
    func 내용이_비어있으면_보낼_수_없다(text: String) async {
        let store = TestStore(initialState: FeedbackFeature.State(text: text)) {
            FeedbackFeature()
        }

        #expect(store.state.canSend == false)
        await store.send(.sendTapped)
    }

    @Test func 전송에_성공하면_부모에게_알린다() async {
        let sent = LockIsolated<(FeedbackCategory, String)?>(nil)
        let store = TestStore(
            initialState: FeedbackFeature.State(category: .bugReport, text: "버그 있어요")
        ) {
            FeedbackFeature()
        } withDependencies: {
            $0.sendFeedbackUseCase.execute = { category, content in
                sent.setValue((category, content))
            }
        }

        await store.send(.sendTapped) {
            $0.isSending = true
        }
        await store.receive(.sendSucceeded) {
            $0.isSending = false
        }
        await store.receive(.delegate(.sent))
        #expect(sent.value?.0 == .bugReport)
        #expect(sent.value?.1 == "버그 있어요")
    }

    @Test func 전송에_실패하면_알림을_띄운다() async {
        let store = TestStore(initialState: FeedbackFeature.State(text: "의견")) {
            FeedbackFeature()
        } withDependencies: {
            $0.sendFeedbackUseCase.execute = { _, _ in throw SendError() }
        }

        await store.send(.sendTapped) {
            $0.isSending = true
        }
        await store.receive(.sendFailed) {
            $0.isSending = false
            $0.alert = AlertState {
                TextState("Failed to send feedback.")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("Please try again in a moment.")
            }
        }
    }

    @Test func 닫기를_누르면_시트를_닫는다() async {
        let isDismissed = LockIsolated(false)
        let store = TestStore(initialState: FeedbackFeature.State()) {
            FeedbackFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { isDismissed.setValue(true) }
        }

        await store.send(.closeTapped)
        #expect(isDismissed.value)
    }
}
