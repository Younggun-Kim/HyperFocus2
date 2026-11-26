import CoreNetwork
import Dependencies
import Domain
import os

// Domain의 포트에 live 구현을 붙인다. `DataModule.bootstrap()`이 직접 참조해 링크와 등록을 보장한다.
extension AuthRepository: @retroactive DependencyKey {
    public static let liveValue = live(
        service: DataNetwork.service,
        tokens: .manager(DataNetwork.tokenManager),
        deviceID: { await DeviceInfo.vendorID }
    )

    /// - Parameters:
    ///   - tokens: 받은 토큰을 넣는 곳. 키체인만 바꾸면 인터셉터가 옛 토큰을 계속 붙이므로 `TokenManager`를 거친다.
    ///   - deviceID: 익명 로그인 때마다 읽는다.
    static func live(
        service: any APIServiceProtocol,
        tokens: TokenAccess,
        deviceID: @escaping @Sendable () async -> String?
    ) -> Self {
        /// 토큰을 받는 요청을 보내고, 받은 토큰으로 바꾼다.
        @Sendable func issueToken(
            _ endpoint: some APIEndpoint<TokenResponseDTO>,
            _ operation: String
        ) async throws {
            try await convertingErrors(operation) {
                let token = try await service.request(endpoint)
                tokens.update(token.toAuthToken())
            }
        }

        return Self(
            hasToken: { tokens.current() != nil },
            signInAnonymously: {
                guard let deviceID = await deviceID() else {
                    Logger.data.error("익명 로그인 실패: 기기 식별자를 읽지 못했다")
                    throw DomainError.unknown
                }
                try await issueToken(AuthAPI.Anonymous(request: AnonymousLoginRequestDTO(deviceId: deviceID)), "익명 로그인")
            },
            linkApple: { request in
                try await issueToken(AuthAPI.LinkApple(request: AppleLinkRequestDTO(request)), "Apple 연동")
            },
            signInWithApple: { request in
                try await issueToken(AuthAPI.LoginApple(request: AppleLoginRequestDTO(request)), "Apple 로그인")
            }
        )
    }
}
