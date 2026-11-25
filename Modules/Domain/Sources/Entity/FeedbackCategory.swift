/// 개발자에게 보내는 피드백의 종류.
/// API에 보내는 문자열은 저장 방식에 묶인 값이라 Data가 매핑한다.
public enum FeedbackCategory: CaseIterable, Sendable, Equatable {
    case featureIdea
    case bugReport
    case other
}
