import Dependencies
import Domain
import Foundation
import Testing

/// UseCase는 지금 Repository에 위임만 한다. 위임이 끊기지 않았는지(값과 에러를 그대로 넘기는지) 확인한다.
struct FetchProfileUseCaseTests {
    private func profile(provider: AccountProvider) -> Profile {
        Profile(
            userId: "00000000-0000-0000-0000-000000000001",
            email: "test@example.com",
            name: "테스트",
            profileImageUrl: nil,
            provider: provider,
            role: "USER",
            status: "ACTIVE",
            lastLoginAt: Date(timeIntervalSince1970: 1_700_000_000),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            profileImageUrlOptional: nil
        )
    }

    @Test func 프로필을_불러오면_저장소의_값을_돌려준다() async throws {
        let stored = profile(provider: .apple)

        let fetched = try await withDependencies {
            $0.authRepository.fetchProfile = { .success(stored) }
        } operation: {
            try await FetchProfileUseCase.liveValue.execute().get()
        }

        #expect(fetched == stored)
    }

    @Test func 저장소의_Domain_에러를_그대로_돌려준다() async {
        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.authRepository.fetchProfile = { .failure(.offline) }
            } operation: {
                try await FetchProfileUseCase.liveValue.execute().get()
            }
        }
    }

    @Test func Apple_계정만_연동된_계정으로_본다() {
        #expect(profile(provider: .apple).isAppleUser == true)
        #expect(profile(provider: .anonymous).isAppleUser == false)
    }
}
