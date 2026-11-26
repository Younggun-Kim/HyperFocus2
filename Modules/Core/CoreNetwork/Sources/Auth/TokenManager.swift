//
//  TokenManager.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/23/26.
//

import Alamofire
import Synchronization

/// 메모리의 토큰(인터셉터)과 저장소의 토큰을 함께 바꾼다.
/// 로그인·로그아웃 시 `update`를 부른다. 갱신 결과는 `TokenAuthenticator`가 저장한다.
public final class TokenManager: Sendable {
    let interceptor: AuthenticationInterceptor<TokenAuthenticator>
    private let storage: any TokenStorage

    /// - Parameters:
    ///   - refresh: 갱신 API 호출. `requiresAuth == false`인 API로 보내야 인터셉터를 다시 타지 않는다.
    ///     서버가 401/403으로 답한 `APIError.httpError`를 세션 만료로 판단한다.
    ///   - onSessionExpired: refresh token이 거절됐을 때 한 번 불린다. 이때 토큰은 이미 지워져 있다.
    ///     네트워크 오류로 갱신에 실패한 경우에는 불리지 않는다.
    public init(
        storage: any TokenStorage,
        refresh: @escaping @Sendable (AuthToken) async -> Result<AuthToken, APIError>,
        onSessionExpired: @escaping @Sendable () -> Void = {}
    ) {
        // authenticator가 interceptor보다 먼저 만들어져야 해서, interceptor는 만든 뒤에 상자에 넣는다.
        // interceptor → authenticator → 클로저 → interceptor 순환을 피하려고 weak로 든다.
        let interceptorRef = WeakInterceptor()
        let authenticator = TokenAuthenticator(storage: storage, refresh: refresh) {
            storage.save(nil)
            interceptorRef.value?.credential = nil
            onSessionExpired()
        }
        self.storage = storage
        self.interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: storage.load()
        )
        interceptorRef.value = interceptor
    }

    public var token: AuthToken? {
        interceptor.credential
    }

    public func update(_ token: AuthToken?) {
        storage.save(token)
        interceptor.credential = token
    }
}

private final class WeakInterceptor: Sendable {
    private struct Box {
        weak var interceptor: AuthenticationInterceptor<TokenAuthenticator>?
    }

    private let box = Mutex(Box())

    var value: AuthenticationInterceptor<TokenAuthenticator>? {
        get { box.withLock { $0.interceptor } }
        set { box.withLock { $0.interceptor = newValue } }
    }
}
