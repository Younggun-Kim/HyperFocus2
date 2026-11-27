//
//  WithdrawUseCaseTests.swift
//  Domain
//
//  Created by 김영건 on 11/27/26.
//

import Dependencies
import Domain
import Testing

struct WithdrawUseCaseTests {

    @Test func 저장소의_withdraw를_호출한다() async throws {
        // Given
        let called = LockIsolated(false)

        // When
        try await withDependencies{
            $0.authRepository.withdraw = {
                called.setValue(true)
                return .success(())
            }
        } operation: {
            try await WithdrawUseCase.liveValue.execute().get()
        }

        // Then
        #expect(called.value)
    }

    @Test func 저장소의_Domain_에러를_그대로_돌려준다() async {
        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.authRepository.withdraw = { .failure(.offline) }
            } operation: {
                try await WithdrawUseCase.liveValue.execute().get()
            }
        }
    }
}
