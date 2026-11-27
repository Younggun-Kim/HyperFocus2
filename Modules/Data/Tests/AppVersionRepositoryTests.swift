import CoreNetwork
import Domain
import Foundation
import Testing
@testable import Data

struct AppVersionRepositoryTests {
    private func json(_ updateType: String, storeUrl: String? = nil) -> String {
        let url = storeUrl.map { "\"\($0)\"" } ?? "null"
        return #"{"success": true, "data": {"platform": "IOS", "currentVersion": "1.0.0", "updateType": "\#(updateType)", "storeUrl": \#(url)}}"#
    }

    @Test func 설치된_버전을_POST로_보낸다() async throws {
        let service = FakeAPIService(.json(json("NONE")))
        let repository = AppVersionRepository.live(service: service, currentVersion: { "1.2.3" })

        _ = try await repository.checkUpdate().get()

        let endpoint = try #require(service.endpoints.first as? AppVersionAPI.Check)
        #expect(endpoint.request == AppVersionCheckRequestDTO(currentVersion: "1.2.3"))
        #expect(endpoint.request.platform == "ios")
        #expect(endpoint.method == .post)
        #expect(!endpoint.requiresAuth)
    }

    @Test(arguments: [
        ("NONE", AppUpdate.Policy.upToDate),
        ("OPTIONAL", .optional),
        ("REQUIRED", .required),
        ("required", .required),
        ("SOMETHING_NEW", .upToDate),
    ])
    func 업데이트_종류를_정책으로_바꾼다(updateType: String, policy: AppUpdate.Policy) async throws {
        let repository = AppVersionRepository.live(service: FakeAPIService(.json(json(updateType))), currentVersion: { "1.0.0" })

        let update = try await repository.checkUpdate().get()

        #expect(update.policy == policy)
    }

    @Test func 스토어_주소를_함께_돌려준다() async throws {
        let service = FakeAPIService(.json(json("REQUIRED", storeUrl: "https://apps.apple.com/app/id1")))
        let repository = AppVersionRepository.live(service: service, currentVersion: { "1.0.0" })

        let update = try await repository.checkUpdate().get()

        #expect(update == AppUpdate(policy: .required, storeURL: URL(string: "https://apps.apple.com/app/id1")))
    }

    @Test func 설치된_버전을_읽지_못하면_요청하지_않고_unknown을_돌려준다() async {
        let service = FakeAPIService(.json(json("NONE")))
        let repository = AppVersionRepository.live(service: service, currentVersion: { nil })

        await #expect(throws: DomainError.unknown) {
            try await repository.checkUpdate().get()
        }
        #expect(service.endpoints.isEmpty)
    }

    @Test func 통신_에러를_Domain_에러로_바꾼다() async {
        let repository = AppVersionRepository.live(
            service: FakeAPIService(.failure(.networkError("offline"))),
            currentVersion: { "1.0.0" }
        )

        await #expect(throws: DomainError.offline) {
            try await repository.checkUpdate().get()
        }
    }
}
