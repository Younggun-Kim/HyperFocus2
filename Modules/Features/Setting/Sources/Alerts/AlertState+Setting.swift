import BaseFeature
import ComposableArchitecture
import Domain

/// 확인 버튼만 있는 실패 알림이라 버튼 액션 타입과 상관없이 쓴다.
extension AlertState {
    /// Apple 로그인 실패 알림.
    /// 로그인 중의 `unauthorized`는 세션 만료가 아니라 서버가 Apple 자격 증명을 거절한 것이므로 알린다.
    static func appleSignInFailure(_ error: DomainError) -> Self? {
        .failure(title: "Couldn't sign in with Apple.", error: error)
    }

    /// 설정 저장 실패 알림.
    static func settingSaveFailure(_ error: DomainError) -> Self? {
        guard !error.isSilentForSetting else { return nil }
        return .failure(title: "Couldn't save your settings.", error: error)
    }

    /// 피드백 전송 실패 알림. 입력한 내용은 그대로 두므로 다시 보내면 된다.
    static func feedbackSendFailure(_ error: DomainError) -> Self? {
        .failure(title: "Failed to send feedback.", error: error)
    }

    /// 탈퇴 실패 알림. 계정은 그대로 남아 있다.
    /// `unauthorized`는 세션 만료라 앱 전역에서 처리하므로 알리지 않는다.
    static func withdrawalFailure(_ error: DomainError) -> Self? {
        guard error != .unauthorized else { return nil }
        return .failure(title: "Couldn't delete your account.", error: error)
    }
}

extension AlertState where Action == SettingFeature.Alert {
    /// 탈퇴 확인 알림. 되돌릴 수 없으므로 삭제를 한 번 더 묻는다.
    static var withdrawalConfirm: Self {
        AlertState {
            TextState("Delete account & data?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmWithdrawal) { TextState("Delete") }
            ButtonState(role: .cancel) { TextState("Keep Account") }
        } message: {
            TextState("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
}

private extension DomainError {
    /// 인증은 앱 전역에서 처리하고, 대상이 없으면 기본값을 쓰면 된다.
    var isSilentForSetting: Bool {
        switch self {
        case .unauthorized, .notFound: true
        default: false
        }
    }
}
