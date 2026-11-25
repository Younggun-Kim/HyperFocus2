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
            case 400, 409, 422: self = .invalid
            default: self = .unknown
            }
        case .decodingError, .unknown, .cancelled:
            self = .unknown
        }
    }
}

/// Repository `liveValue`의 통신을 감싸, 아래 계층 에러를 로깅한 뒤 Domain 에러로 바꿔 던진다.
///
/// - 취소는 에러가 아니라 흐름이다. `APIError.cancelled`도 `CancellationError`로 바꿔 Feature가 무시하게 한다.
/// - `DomainError`는 이미 변환된 값이므로 그대로 둔다.
func convertingErrors<T: Sendable>(
    _ operation: String,
    _ body: () async throws -> T
) async throws -> T {
    do {
        return try await body()
    } catch is CancellationError {
        throw CancellationError()
    } catch let error as DomainError {
        throw error
    } catch let error as APIError {
        if case .cancelled = error { throw CancellationError() }
        Logger.data.error("\(operation) 실패: \(String(describing: error))")
        throw DomainError(error)
    } catch {
        Logger.data.error("\(operation) 실패: \(String(describing: error))")
        throw DomainError.unknown
    }
}
