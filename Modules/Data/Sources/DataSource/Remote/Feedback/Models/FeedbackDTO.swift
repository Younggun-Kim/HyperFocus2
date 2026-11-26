import Domain

struct FeedbackRequestDTO: Encodable, Sendable, Equatable {
    /// 서버 값: `feature` | `bug` | `other`
    let category: String
    let content: String
    let appVersion: String?
    let deviceModel: String?
    let osVersion: String?
}

extension FeedbackCategory {
    /// API에 보내는 문자열. 저장 방식에 묶인 값이라 Domain이 아니라 여기 둔다.
    var apiValue: String {
        switch self {
        case .featureIdea: return "feature"
        case .bugReport: return "bug"
        case .other: return "other"
        }
    }
}
