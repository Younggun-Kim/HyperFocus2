import Dependencies
import Domain
import Testing

/// UseCase는 지금 Repository에 위임만 한다. 위임이 끊기지 않았는지 확인한다.
struct CheckAppUpdateUseCaseTests {
    @Test func 저장소의_업데이트_정책을_돌려준다() async throws {
        let update = try await withDependencies {
            $0.appVersionRepository.checkUpdate = { .success(AppUpdate(policy: .required)) }
        } operation: {
            try await CheckAppUpdateUseCase.liveValue.execute().get()
        }

        #expect(update == AppUpdate(policy: .required))
    }

    @Test func 저장소의_Domain_에러를_그대로_돌려준다() async {
        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.appVersionRepository.checkUpdate = { .failure(.offline) }
            } operation: {
                try await CheckAppUpdateUseCase.liveValue.execute().get()
            }
        }
    }
}
