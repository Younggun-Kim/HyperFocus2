import ComposableArchitecture
import Domain

extension DomainError {
    /// 실패 알림 본문에 쓰는 사용자 문구. 취소는 알리지 않으므로 nil.
    public var failureMessage: String? {
        switch self {
        case .cancelled:
            nil
        case .offline:
            "Please check your internet connection."
        case .unauthorized, .notFound, .invalid, .conflict, .unknown:
            "Please try again in a moment."
        }
    }
}

/// 확인 버튼만 있어 버튼 액션 타입과 상관없이 쓴다.
extension AlertState {
    /// 확인 버튼 하나만 있는 실패 알림. 알릴 필요가 없는 에러면 nil.
    public static func failure(title: String, error: DomainError) -> Self? {
        guard let message = error.failureMessage else { return nil }
        return AlertState {
            TextState(title)
        } actions: {
            ButtonState(role: .cancel) { TextState("OK") }
        } message: {
            TextState(message)
        }
    }
}
