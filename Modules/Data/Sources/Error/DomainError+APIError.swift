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
        case .decodingError, .unknown, .cancelled:
            self = .unknown
        }
    }
}

extension Result where Failure == APIError {
    /// 성공 값을 꺼낸다. 실패면 원본을 로깅한 뒤 Domain 에러로 바꿔 던진다.
    ///
    /// 취소는 에러가 아니라 흐름이다. `APIError.cancelled`는 `CancellationError`로 바꿔 Feature가 무시하게 한다.
    func orThrowDomainError(_ operation: String) throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(.cancelled):
            throw CancellationError()
        case .failure(let error):
            Logger.data.error("\(operation) 실패: \(String(describing: error))")
            throw DomainError(error)
        }
    }
}
