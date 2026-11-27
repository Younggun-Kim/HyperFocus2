import CoreNetwork
import Dependencies
import Domain
import Foundation
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

        try await repository(service, stored: stored).signInAnonymously().get()

        let endpoint = try #require(service.endpoints.first as? AuthAPI.Anonymous)
        #expect(endpoint.request == AnonymousLoginRequestDTO(deviceId: "test-device"))
        #expect(endpoint.requiresAuth == false)
        #expect(stored.value == issued)
    }

    @Test func 기기_식별자가_없으면_요청하지_않고_unknown을_돌려준다() async {
        let service = FakeAPIService(.json(tokenJSON))
        let stored = LockIsolated<AuthToken?>(nil)

        await #expect(throws: DomainError.unknown) {
            try await repository(service, stored: stored, deviceID: nil).signInAnonymously().get()
        }
        #expect(service.endpoints.isEmpty)
    }

    @Test func 연동은_없는_이름과_email을_빈_문자열로_보낸다() async throws {
        let service = FakeAPIService(.json(tokenJSON))
        let stored = LockIsolated<AuthToken?>(nil)

        try await repository(service, stored: stored).linkApple(request).get()

        let endpoint = try #require(service.endpoints.first as? AuthAPI.LinkApple)
        #expect(endpoint.request == AppleLinkRequestDTO(
            identityToken: "test-identity-token",
            authorizationCode: "test-code",
            name: "",
            email: ""
        ))
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

        try await repository(service, stored: stored).signInWithApple(request).get()

        let endpoint = try #require(service.endpoints.first as? AuthAPI.LoginApple)
        #expect(endpoint.request == AppleLoginRequestDTO(
            identityToken: "test-identity-token",
            name: "테스트",
            email: "test@example.com"
        ))
        #expect(stored.value == issued)
    }

    @Test func 이미_연동된_Apple_계정이면_conflict를_돌려준다() async {
        let service = FakeAPIService(.failure(APIError.httpError(statusCode: 409, message: nil)))
        let stored = LockIsolated<AuthToken?>(nil)

        await #expect(throws: DomainError.conflict) {
            try await repository(service, stored: stored).linkApple(request).get()
        }
        #expect(stored.value == nil)
    }

    @Test func 응답에_토큰이_없으면_저장하지_않고_unknown을_돌려준다() async {
        let service = FakeAPIService(.json(#"{"success": true, "data": null}"#))
        let stored = LockIsolated<AuthToken?>(nil)

        await #expect(throws: DomainError.unknown) {
            try await repository(service, stored: stored).linkApple(request).get()
        }
        #expect(stored.value == nil)
    }

    // MARK: - 프로필 조회

    /// 서버 응답과 같은 모양. 식별자와 email은 가짜 값이다.
    private func profileJSON(provider: String) -> String {
        """
        {
          "success": true,
          "data": {
            "userId": "00000000-0000-0000-0000-000000000001",
            "email": "test@example.com",
            "name": "테스트",
            "profileImageUrl": null,
            "provider": "\(provider)",
            "role": "USER",
            "status": "ACTIVE",
            "lastLoginAt": "2026-11-20T05:00:14",
            "createdAt": "2026-11-19T05:00:14",
            "profileImageUrlOptional": null
          }
        }
        """
    }

    @Test func 프로필_조회는_토큰을_붙여_보내고_응답을_Entity로_바꾼다() async throws {
        let service = FakeAPIService(.json(profileJSON(provider: "APPLE")))

        let profile = try await repository(service, stored: LockIsolated(issued)).fetchProfile().get()

        let endpoint = try #require(service.endpoints.first as? AuthAPI.Me)
        #expect(endpoint.path == "/api/v1/auth/me")
        #expect(endpoint.method == .get)
        #expect(endpoint.requiresAuth == true)
        #expect(profile == Profile(
            userId: "00000000-0000-0000-0000-000000000001",
            email: "test@example.com",
            name: "테스트",
            profileImageUrl: nil,
            provider: .apple,
            role: "USER",
            status: "ACTIVE",
            lastLoginAt: try Date("2026-11-20T05:00:14Z", strategy: .iso8601),
            createdAt: try Date("2026-11-19T05:00:14Z", strategy: .iso8601),
            profileImageUrlOptional: nil
        ))
    }

    @Test(arguments: [
        ("APPLE", AccountProvider.apple, true),
        ("ANONYMOUS", AccountProvider.anonymous, false),
    ])
    func 서버의_provider를_Domain_값으로_바꾼다(serverKey: String, provider: AccountProvider, isAppleUser: Bool) async throws {
        let service = FakeAPIService(.json(profileJSON(provider: serverKey)))

        let profile = try await repository(service, stored: LockIsolated(issued)).fetchProfile().get()

        #expect(profile.provider == provider)
        #expect(profile.isAppleUser == isAppleUser)
    }

    @Test func 모르는_provider면_unknown을_돌려준다() async {
        let service = FakeAPIService(.json(profileJSON(provider: "GOOGLE")))

        await #expect(throws: DomainError.unknown) {
            try await repository(service, stored: LockIsolated(issued)).fetchProfile().get()
        }
    }

    @Test func 프로필_조회가_인증_실패면_unauthorized를_돌려준다() async {
        let service = FakeAPIService(.failure(APIError.httpError(statusCode: 401, message: nil)))

        await #expect(throws: DomainError.unauthorized) {
            try await repository(service, stored: LockIsolated(issued)).fetchProfile().get()
        }
    }

    // MARK: - 로그아웃

    @Test func 로그아웃은_토큰을_붙여_보내고_저장된_토큰을_지운다() async throws {
        let service = FakeAPIService(.json(#"{"success": true}"#))
        let stored = LockIsolated<AuthToken?>(issued)

        try await repository(service, stored: stored).logout().get()

        let endpoint = try #require(service.endpoints.first as? AuthAPI.Logout)
        #expect(endpoint.path == "/api/v1/auth/logout")
        #expect(endpoint.method == .post)
        #expect(endpoint.requiresAuth == true)
        #expect(stored.value == nil)
    }

    @Test func 로그아웃_요청이_실패해도_토큰을_지우고_에러를_돌려준다() async {
        let service = FakeAPIService(.failure(APIError.networkError("test")))
        let stored = LockIsolated<AuthToken?>(issued)

        await #expect(throws: DomainError.self) {
            try await repository(service, stored: stored).logout().get()
        }
        #expect(stored.value == nil)
    }
}
