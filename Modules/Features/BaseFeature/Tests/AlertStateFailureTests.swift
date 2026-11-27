import BaseFeature
import ComposableArchitecture
import Domain
import Testing

struct AlertStateFailureTests {

    @Test
    func 취소는_문구가_없다() {
        #expect(DomainError.cancelled.failureMessage == nil)
    }

    @Test
    func 오프라인은_연결_확인_문구를_쓴다() {
        #expect(DomainError.offline.failureMessage == "Please check your internet connection.")
    }

    @Test(arguments: [DomainError.unauthorized, .notFound, .invalid, .conflict, .unknown])
    func 그_밖의_에러는_재시도_문구를_쓴다(error: DomainError) {
        #expect(error.failureMessage == "Please try again in a moment.")
    }

    @Test
    func 취소는_알림을_만들지_않는다() {
        #expect(AlertState<Never>.failure(title: "Title", error: .cancelled) == nil)
    }

    @Test
    func 실패_알림은_제목과_문구와_확인_버튼을_가진다() {
        let alert = AlertState<Never>.failure(title: "Title", error: .offline)

        #expect(
            alert == AlertState {
                TextState("Title")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("Please check your internet connection.")
            }
        )
    }
}
