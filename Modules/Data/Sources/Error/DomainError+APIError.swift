import CoreNetwork
import Domain
import os

extension DomainError {
    /// 통신 사실(`APIError`)을 Domain의 언어로 바꾼다.
    init(_ error: APIError) {
        switch error {
        case .networkError:
            self = .offline
        case .tokenNotFound, .sessionExpired:
            self = .unauthorized
        case let .httpError(statusCode, _):
            switch statusCode {
            case 401, 403: self = .unauthorized
            case 404: self = .notFound
            case 400, 422: self = .invalid
            case 409: self = .conflict
            default: self = .unknown
            }
        case .cancelled:
            self = .cancelled
        case .decodingError, .unknown:
            self = .unknown
        }
    }
}

extension Result where Failure == APIError {
    /// 실패를 Domain 에러로 바꾼다. 바꾸기 전에 원본을 로깅한다.
    ///
    /// 취소는 실패가 아니라 흐름이라 로깅하지 않는다.
    func domainResult(_ operation: String) -> Result<Success, DomainError> {
        mapError { error in
            let domainError = DomainError(error)
            if domainError != .cancelled {
                Logger.data.error("\(operation) 실패: \(String(describing: error))")
            }
            return domainError
        }
    }
}
