import Dependencies
import DependenciesMacros

/// 개발자에게 피드백을 보낸다.
@DependencyClient
public struct SendFeedbackUseCase: Sendable {
    public var execute: @Sendable (_ category: FeedbackCategory, _ content: String) async -> Result<Void, DomainError> = { _, _ in .failure(.unknown) }
}

extension DependencyValues {
    public var sendFeedbackUseCase: SendFeedbackUseCase {
        get { self[SendFeedbackUseCase.self] }
        set { self[SendFeedbackUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
// 선언과 같은 파일에 두어 Feature가 선언을 참조하면 liveValue도 함께 링크되게 한다.
extension SendFeedbackUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: { category, content in
            @Dependency(\.feedbackRepository) var feedbackRepository
            return await feedbackRepository.sendFeedback(category, content)
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
