import CoreNetwork
import Dependencies
import Domain
import Testing
@testable import Data

struct AuthRepositoryTests {
    private let tokenJSON = #"{"success": true, "data": {"accessToken": "test-access", "refreshToken": "test-refresh", "tokenType": "Bearer"}}"#
    private let issued = AuthToken(accessToken: "test-access", refreshToken: "test-refresh", tokenType: "Bearer")
    private let request = AppleSignInRequest(
        identityToken: "test-identity-token",
        authorizationCode: "test-code",
        name: nil,
        email: nil
    )

    private func repository(
        _ service: FakeAPIService,
        stored: LockIsolated<AuthToken?>,
        deviceID: String? = "test-device"
    ) -> AuthRepository {
        AuthRepository.live(
            service: service,
            tokens: TokenAccess(current: { stored.value }, update: { stored.setValue($0) }),
            deviceID: { deviceID }
        )
    }

    @Test func 저장된_토큰이_있는지_알려준다() {
        let stored = LockIsolated<AuthToken?>(nil)
        let repository = repository(FakeAPIService(.json(tokenJSON)), stored: stored)

        #expect(repository.hasToken() == false)
        stored.setValue(issued)
        #expect(repository.hasToken() == true)
    }

    @Test func 익명_로그인은_기기_식별자를_보내고_받은_토큰을_저장한다() async throws {
        let service = FakeAPIService(.json(tokenJSON))
        let stored = LockIsolated<AuthToken?>(nil)

        try await repository(service, stored: stored).signInAnonymously()

        let endpoint = try #require(service.endpoints.first as? AuthEndpoint)
        #expect(endpoint == .anonymous(AnonymousLoginRequestDTO(deviceId: "test-device")))
        #expect(endpoint.requiresAuth == false)
        #expect(stored.value == issued)
    }

    @Test func 기기_식별자가_없으면_요청하지_않고_unknown을_던진다() async {
        let service = FakeAPIService(.json(tokenJSON))
        let stored = LockIsolated<AuthToken?>(nil)

        await #expect(throws: DomainError.unknown) {
            try await repository(service, stored: stored, deviceID: nil).signInAnonymously()
        }
        #expect(service.endpoints.isEmpty)
    }

    @Test func 연동은_없는_이름과_email을_빈_문자열로_보낸다() async throws {
        let service = FakeAPIService(.json(tokenJSON))
        let stored = LockIsolated<AuthToken?>(nil)

        try await repository(service, stored: stored).linkApple(request)

        let endpoint = try #require(service.endpoints.first as? AuthEndpoint)
        #expect(endpoint == .linkApple(AppleLinkRequestDTO(
            identityToken: "test-identity-token",
            authorizationCode: "test-code",
            name: "",
            email: ""
        )))
        #expect(endpoint.requiresAuth == true)
        #expect(stored.value == issued)
    }

    @Test func 로그인은_받은_이름과_email을_보내고_토큰을_저장한다() async throws {
        let service = FakeAPIService(.json(tokenJSON))
        let stored = LockIsolated<AuthToken?>(nil)
        let request = AppleSignInRequest(
            identityToken: "test-identity-token",
            authorizationCode: "test-code",
            name: "테스트",
            email: "test@example.com"
        )

        try await repository(service, stored: stored).signInWithApple(request)

        let endpoint = try #require(service.endpoints.first as? AuthEndpoint)
        #expect(endpoint == .loginApple(AppleLoginRequestDTO(
            identityToken: "test-identity-token",
            name: "테스트",
            email: "test@example.com"
        )))
        #expect(stored.value == issued)
    }

    @Test func 이미_연동된_Apple_계정이면_conflict를_던진다() async {
        let service = FakeAPIService(.failure(APIError.httpError(statusCode: 409, message: nil)))
        let stored = LockIsolated<AuthToken?>(nil)

        await #expect(throws: DomainError.conflict) {
            try await repository(service, stored: stored).linkApple(request)
        }
        #expect(stored.value == nil)
    }

    @Test func 응답에_토큰이_없으면_저장하지_않고_unknown을_던진다() async {
        let service = FakeAPIService(.json(#"{"success": true, "data": null}"#))
        let stored = LockIsolated<AuthToken?>(nil)

        await #expect(throws: DomainError.unknown) {
            try await repository(service, stored: stored).linkApple(request)
        }
        #expect(stored.value == nil)
    }
}
