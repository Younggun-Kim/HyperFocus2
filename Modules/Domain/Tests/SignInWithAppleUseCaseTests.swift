import Dependencies
import Domain
import Testing

/// 익명 로그인 → 연동 → (이미 연동된 계정이면) 로그인 순서를 검증한다.
struct SignInWithAppleUseCaseTests {
    private let request = AppleSignInRequest(
        identityToken: "test-identity-token",
        authorizationCode: "test-code",
        name: nil,
        email: nil
    )

    /// 호출된 Repository 메서드 이름을 순서대로 남긴다.
    private func repository(
        hasToken: Bool,
        link: @escaping @Sendable () throws -> Void = {},
        calls: LockIsolated<[String]>
    ) -> AuthRepository {
        AuthRepository(
            hasToken: { hasToken },
            signInAnonymously: { calls.withValue { $0.append("anonymous") } },
            linkApple: { _ in
                calls.withValue { $0.append("link") }
                try link()
            },
            signInWithApple: { _ in calls.withValue { $0.append("login") } }
        )
    }

    @Test func 토큰이_없으면_익명_로그인부터_하고_연동한다() async throws {
        let calls = LockIsolated<[String]>([])

        try await withDependencies {
            $0.authRepository = repository(hasToken: false, calls: calls)
        } operation: {
            try await SignInWithAppleUseCase.liveValue.execute(request)
        }

        #expect(calls.value == ["anonymous", "link"])
    }

    @Test func 토큰이_있으면_익명_로그인을_건너뛴다() async throws {
        let calls = LockIsolated<[String]>([])

        try await withDependencies {
            $0.authRepository = repository(hasToken: true, calls: calls)
        } operation: {
            try await SignInWithAppleUseCase.liveValue.execute(request)
        }

        #expect(calls.value == ["link"])
    }

    @Test func 이미_연동된_계정이면_그_계정으로_로그인한다() async throws {
        let calls = LockIsolated<[String]>([])

        try await withDependencies {
            $0.authRepository = repository(hasToken: true, link: { throw DomainError.conflict }, calls: calls)
        } operation: {
            try await SignInWithAppleUseCase.liveValue.execute(request)
        }

        #expect(calls.value == ["link", "login"])
    }

    @Test func 연동이_다른_이유로_실패하면_로그인하지_않고_에러를_던진다() async {
        let calls = LockIsolated<[String]>([])

        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.authRepository = repository(hasToken: true, link: { throw DomainError.offline }, calls: calls)
            } operation: {
                try await SignInWithAppleUseCase.liveValue.execute(request)
            }
        }
        #expect(calls.value == ["link"])
    }
}
