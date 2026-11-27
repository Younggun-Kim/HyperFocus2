import Dependencies
import Domain
import Testing

/// UseCase는 지금 Repository에 위임만 한다. 위임이 끊기지 않았는지 확인한다.
struct LogoutUseCaseTests {
    @Test func 저장소의_로그아웃을_부른다() async throws {
        let called = LockIsolated(false)

        try await withDependencies {
            $0.authRepository.logout = {
                called.setValue(true)
                return .success(())
            }
        } operation: {
            try await LogoutUseCase.liveValue.execute().get()
        }

        #expect(called.value)
    }

    @Test func 저장소의_Domain_에러를_그대로_돌려준다() async {
        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.authRepository.logout = { .failure(.offline) }
            } operation: {
                try await LogoutUseCase.liveValue.execute().get()
            }
        }
    }
}
