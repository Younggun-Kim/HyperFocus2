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

    init(storage: any TokenStorage, refresh: @escaping Refresh) {
        self.storage = storage
        self.refresh = refresh
    }

    func apply(_ credential: AuthToken, to urlRequest: inout URLRequest) {
        urlRequest.setValue(credential.authorizationHeader, forHTTPHeaderField: "Authorization")
    }

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
}
