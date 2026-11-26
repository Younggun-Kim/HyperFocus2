import ComposableArchitecture
import Domain
import Testing
@testable import Setting

@MainActor
struct FeedbackFeatureTests {
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
                return .success(())
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
            $0.sendFeedbackUseCase.execute = { _, _ in .failure(.invalid) }
        }

        await store.send(.sendTapped) {
            $0.isSending = true
        }
        await store.receive(.sendFailed(.invalid)) {
            $0.isSending = false
            $0.alert = AlertState {
                TextState("Failed to send feedback.")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("Please try again in a moment.")
            }
        }
        #expect(store.state.text == "의견")
    }

    @Test func 오프라인이면_연결을_확인하라고_알린다() async {
        let store = TestStore(initialState: FeedbackFeature.State(text: "의견")) {
            FeedbackFeature()
        } withDependencies: {
            $0.sendFeedbackUseCase.execute = { _, _ in .failure(.offline) }
        }

        await store.send(.sendTapped) {
            $0.isSending = true
        }
        await store.receive(.sendFailed(.offline)) {
            $0.isSending = false
            $0.alert = AlertState {
                TextState("Failed to send feedback.")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("Please check your internet connection.")
            }
        }
    }

    @Test func 취소되면_알리지_않고_전송_중만_푼다() async {
        let store = TestStore(initialState: FeedbackFeature.State(text: "의견")) {
            FeedbackFeature()
        } withDependencies: {
            $0.sendFeedbackUseCase.execute = { _, _ in .failure(.cancelled) }
        }

        await store.send(.sendTapped) {
            $0.isSending = true
        }
        await store.receive(.sendFailed(.cancelled)) {
            $0.isSending = false
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
