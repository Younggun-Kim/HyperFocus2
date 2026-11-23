//
//  TokenManager.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/23/26.
//

import Alamofire

/// 메모리의 토큰(인터셉터)과 저장소의 토큰을 함께 바꾼다.
/// 로그인·로그아웃 시 `update`를 부른다. 갱신 결과는 `TokenAuthenticator`가 저장한다.
public final class TokenManager: Sendable {
    let interceptor: AuthenticationInterceptor<TokenAuthenticator>
    private let storage: any TokenStorage

    /// - Parameter refresh: 갱신 API 호출. `requiresAuth == false`인 target으로 보내야 인터셉터를 다시 타지 않는다.
    public init(
        storage: any TokenStorage,
        refresh: @escaping @Sendable (AuthToken) async throws -> AuthToken
    ) {
        self.storage = storage
        self.interceptor = AuthenticationInterceptor(
            authenticator: TokenAuthenticator(storage: storage, refresh: refresh),
            credential: storage.load()
        )
    }

    public var token: AuthToken? {
        interceptor.credential
    }

    public func update(_ token: AuthToken?) {
        storage.save(token)
        interceptor.credential = token
    }
}
