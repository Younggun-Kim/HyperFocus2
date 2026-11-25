import Dependencies
import DependenciesMacros

/// 피드백 전송 포트. 구현(`liveValue`)은 Data 모듈에 둔다.
/// Feature는 이 타입을 직접 쓰지 않고 `SendFeedbackUseCase`를 통해서만 접근한다.
@DependencyClient
public struct FeedbackRepository: Sendable {
    public var sendFeedback: @Sendable (_ category: FeedbackCategory, _ content: String) async throws -> Void
}

extension DependencyValues {
    public var feedbackRepository: FeedbackRepository {
        get { self[FeedbackRepository.self] }
        set { self[FeedbackRepository.self] = newValue }
    }
}

extension FeedbackRepository: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        sendFeedback: { _, _ in }
    )
}
