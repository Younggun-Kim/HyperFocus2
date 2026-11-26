import CoreNetwork
import Domain
import Testing
@testable import Data

struct FeedbackRepositoryTests {
    private let device = DeviceInfo(appVersion: "1.2.0", deviceModel: "iPhone17,1", osVersion: "18.0.0")

    @Test(arguments: [
        (FeedbackCategory.featureIdea, "feature"),
        (.bugReport, "bug"),
        (.other, "other"),
    ])
    func 카테고리와_기기_정보를_함께_보낸다(category: FeedbackCategory, apiValue: String) async throws {
        let service = FakeAPIService(.json(#"{"success": true, "data": {"id": "1"}}"#))
        let repository = FeedbackRepository.live(service: service, device: { [device] in device })

        try await repository.sendFeedback(category, "의견")

        let endpoint = try #require(service.endpoints.first as? FeedbackAPI)
        #expect(endpoint == .send(FeedbackRequestDTO(
            category: apiValue,
            content: "의견",
            appVersion: "1.2.0",
            deviceModel: "iPhone17,1",
            osVersion: "18.0.0"
        )))
    }

    @Test func 서버가_거절하면_invalid를_던진다() async {
        let service = FakeAPIService(.failure(APIError.httpError(statusCode: 400, message: nil)))
        let repository = FeedbackRepository.live(service: service, device: { [device] in device })

        await #expect(throws: DomainError.invalid) {
            try await repository.sendFeedback(.other, "의견")
        }
    }
}
