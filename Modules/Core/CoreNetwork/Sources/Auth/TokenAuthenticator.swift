//
//  TokenAuthenticator.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/23/26.
//

import Foundation
import Alamofire

final class TokenAuthenticator: Authenticator {
    typealias Refresh = @Sendable (AuthToken) async throws -> AuthToken

    private let storage: any TokenStorage
    private let refresh: Refresh
    private let onSessionExpired: @Sendable () -> Void

    /// - Parameter onSessionExpired: refresh token이 거절됐을 때 불린다.
    ///   `refresh`는 동시에 한 번만 실행되므로, 요청이 몇 개 실패하든 한 번만 불린다.
    init(
        storage: any TokenStorage,
        refresh: @escaping Refresh,
        onSessionExpired: @escaping @Sendable () -> Void
    ) {
        self.storage = storage
        self.refresh = refresh
        self.onSessionExpired = onSessionExpired
    }

    func apply(_ credential: AuthToken, to urlRequest: inout URLRequest) {
        urlRequest.setValue(credential.authorizationHeader, forHTTPHeaderField: "Authorization")
    }

    /// 갱신 결과는 세 가지다.
    /// - 성공: 새 토큰을 저장하고 재시도
    /// - refresh token 거절(401/403): 세션 만료. `APIError.sessionExpired`로 끝낸다
    /// - 그 밖의 실패(네트워크 오류 등): 세션을 유지하고 에러만 전달한다
    func refresh(
        _ credential: AuthToken,
        for session: Session,
        completion: @escaping @Sendable (Result<AuthToken, any Error>) -> Void
    ) {
        Task {
            do {
                let token = try await refresh(credential)
                storage.save(token)
                completion(.success(token))
            } catch where Self.isRefreshTokenRejected(error) {
                // completion보다 먼저 불러야 한다. 기다리던 요청이 끝나기 전에 토큰이 지워져 있어야
                // 뒤이어 나가는 요청이 옛 토큰으로 다시 401을 받고 갱신을 또 시도하지 않는다.
                onSessionExpired()
                completion(.failure(APIError.sessionExpired))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func didRequest(
        _ urlRequest: URLRequest,
        with response: HTTPURLResponse,
        failDueToAuthenticationError error: any Error
    ) -> Bool {
        response.statusCode == 401
    }

    /// `false`면 이미 갱신된 토큰이 있으므로 갱신 없이 재시도한다.
    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: AuthToken) -> Bool {
        urlRequest.value(forHTTPHeaderField: "Authorization") == credential.authorizationHeader
    }

    /// 서버가 갱신 요청에 401/403으로 답했으면 refresh token이 무효다.
    /// 응답 자체가 없는 실패(오프라인, 타임아웃)는 여기에 해당하지 않는다.
    private static func isRefreshTokenRejected(_ error: any Error) -> Bool {
        guard case .httpError(let statusCode, _)? = error as? APIError else {
            return false
        }
        return statusCode == 401 || statusCode == 403
    }
}
