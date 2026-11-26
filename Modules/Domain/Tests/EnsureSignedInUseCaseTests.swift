//
//  EnsureSignedInUseCaseTests.swift
//  Domain
//
//  Created by 김영건 on 11/26/26.
//

import Dependencies
import Domain
import Testing

struct EnsureSignedInUseCaseTests {
    
    /// 호출된 Repository 메서드 이름을 순서대로 남긴다.
    private func repository(
        hasToken: Bool,
        signInAnonymously: @escaping @Sendable () throws -> Void = {},
        calls: LockIsolated<[String]>
    ) -> AuthRepository {
        AuthRepository(
            hasToken: { hasToken },
            signInAnonymously: {
                calls.withValue { $0.append("anonymous") }
                try signInAnonymously()
            },
            linkApple: { _ in },
            signInWithApple: { _ in }
        )
    }
    
    @Test func 저장된_토큰이_있으면_익명_로그인을_하지_않는다() async throws {
        // Given
        let calls = LockIsolated<[String]>([])
        
        // When
        try await withDependencies {
            $0.authRepository = repository(hasToken: true, calls: calls)
        } operation: {
            try await EnsureSignedInUseCase.liveValue.execute()
        }
        
        // Then
        #expect(calls.isEmpty)
    }
    
    @Test func 저장된_토큰이_없으면_익명_로그인을_한다() async throws {
        // Given
        let calls = LockIsolated<[String]>([])
        
        // When
        try await withDependencies {
            $0.authRepository = repository(hasToken: false, calls: calls)
        } operation: {
            try await EnsureSignedInUseCase.liveValue.execute()
        }
        
        // Then
        #expect(calls.value == ["anonymous"])
    }
    
    @Test func 익명_로그인에_실패하면_에러를_반환한다() async throws {
        // Given
        let calls = LockIsolated<[String]>([])
        
        // When
        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.authRepository = repository(
                    hasToken: false,
                    signInAnonymously: {
                        throw DomainError.offline
                    },
                    calls: calls
                )
            } operation: {
                try await EnsureSignedInUseCase.liveValue.execute()
            }
        }
        
        // Then
        #expect(calls.value == ["anonymous"])
    }
}
