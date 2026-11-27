import CoreNetwork
import Dependencies
import Domain
import os

// Domain의 포트에 live 구현을 붙인다. `DataModule.bootstrap()`이 직접 참조해 링크와 등록을 보장한다.
extension AuthRepository: @retroactive DependencyKey {
    public static let liveValue = live(
        service: DataNetwork.service,
        tokens: .manager(DataNetwork.tokenManager),
        deviceID: { await DeviceInfo.vendorID },
        sessionExpired: { DataNetwork.sessionExpiry.stream() }
    )

    /// - Parameters:
    ///   - tokens: 받은 토큰을 넣는 곳. 키체인만 바꾸면 인터셉터가 옛 토큰을 계속 붙이므로 `TokenManager`를 거친다.
    ///   - deviceID: 익명 로그인 때마다 읽는다.
    ///   - sessionExpired: 세션 만료 스트림. 만료는 `TokenManager`가 알리므로 그대로 넘긴다.
    static func live(
        service: any APIServiceProtocol,
        tokens: TokenAccess,
        deviceID: @escaping @Sendable () async -> String?,
        sessionExpired: @escaping @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } }
    ) -> Self {
        /// 토큰을 받는 요청을 보내고, 받은 토큰으로 바꾼다.
        @Sendable func issueToken(
            _ endpoint: some APIEndpoint<TokenResponseDTO>,
            _ operation: String
        ) async -> Result<Void, DomainError> {
            await service.request(endpoint).domainResult(operation).map { token in
                tokens.update(token.toAuthToken())
            }
        }

        return Self(
            hasToken: { tokens.current() != nil },
            signInAnonymously: {
                guard let deviceID = await deviceID() else {
                    Logger.data.error("익명 로그인 실패: 기기 식별자를 읽지 못했다")
                    return .failure(.unknown)
                }
                return await issueToken(AuthAPI.Anonymous(request: AnonymousLoginRequestDTO(deviceId: deviceID)), "익명 로그인")
            },
            linkApple: { request in
                await issueToken(AuthAPI.LinkApple(request: AppleLinkRequestDTO(request)), "Apple 연동")
            },
            signInWithApple: { request in
                await issueToken(AuthAPI.LoginApple(request: AppleLoginRequestDTO(request)), "Apple 로그인")
            },
            fetchProfile: {
                await service.request(AuthAPI.Me())
                    .domainResult("프로필 조회")
                    .flatMap { response in response.toEntity() }
            },
            logout: {
                let result = await service.request(AuthAPI.Logout())
                    .domainResult("로그아웃")
                    .map { _ in }
                // 서버 요청이 실패해도 이 기기에서는 로그아웃한다.
                tokens.update(nil)
                return result
            },
            withdraw: {
                let result = await service.request(AuthAPI.Withdraw())
                    .domainResult("탈퇴")
                    .map { _ in }
                // 서버에 계정이 남아 있으면 다시 시도할 수 있게 토큰을 둔다.
                if case .success = result {
                    tokens.update(nil)
                }
                return result
            },
            sessionExpired: sessionExpired,
        )
    }
}
