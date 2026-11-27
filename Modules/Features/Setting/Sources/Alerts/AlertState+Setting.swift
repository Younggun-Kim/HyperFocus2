import ComposableArchitecture
import Domain

extension DomainError {
    /// 실패 알림 본문에 쓰는 사용자 문구. 취소는 알리지 않으므로 nil.
    var failureMessage: String? {
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

extension AlertState {
    /// 확인 버튼 하나만 있는 실패 알림. 알릴 필요가 없는 에러면 nil.
    static func failure(title: String, error: DomainError) -> Self? {
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

extension AlertState where Action == Never {
    /// Apple 로그인 실패 알림.
    /// 로그인 중의 `unauthorized`는 세션 만료가 아니라 서버가 Apple 자격 증명을 거절한 것이므로 알린다.
    static func appleSignInFailure(_ error: DomainError) -> Self? {
        .failure(title: "Couldn't sign in with Apple.", error: error)
    }

    /// 설정 조회 실패 알림.
    static func settingLoadFailure(_ error: DomainError) -> Self? {
        guard !error.isSilentForSetting else { return nil }
        return .failure(title: "Couldn't load your settings.", error: error)
    }

    /// 설정 저장 실패 알림.
    static func settingSaveFailure(_ error: DomainError) -> Self? {
        guard !error.isSilentForSetting else { return nil }
        return .failure(title: "Couldn't save your settings.", error: error)
    }
}

private extension DomainError {
    /// 인증은 앱 전역에서 처리하고, 저장된 설정이 없으면 기본값을 쓰면 된다.
    var isSilentForSetting: Bool {
        switch self {
        case .unauthorized, .notFound: true
        default: false
        }
    }
}
