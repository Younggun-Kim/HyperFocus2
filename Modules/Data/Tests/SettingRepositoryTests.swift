import CoreNetwork
import Domain
import Testing
@testable import Data

struct SettingRepositoryTests {
    private let settingJSON = #"{"success": true, "data": {"soundEnabled": true, "hapticEnabled": false, "alarmEnabled": true}}"#

    @Test func 설정을_조회하면_응답을_Entity로_바꾼다() async throws {
        let service = FakeAPIService(.json(settingJSON))
        let repository = SettingRepository.live(service: service)

        let setting = try await repository.fetchSetting().get()

        #expect(setting == AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: true))
        #expect(service.endpoints.first is SettingAPI.Fetch)
    }

    @Test func 설정을_변경하면_전체_값을_PATCH로_보내고_서버_값을_돌려준다() async throws {
        let service = FakeAPIService(.json(settingJSON))
        let repository = SettingRepository.live(service: service)
        let requested = AppSetting(soundEnabled: true, hapticEnabled: true, alarmEnabled: true)

        let setting = try await repository.updateSetting(requested).get()

        let endpoint = try #require(service.endpoints.first as? SettingAPI.Update)
        #expect(endpoint.request == SettingRequestDTO(requested))
        #expect(endpoint.method == .patch)
        #expect(setting == AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: true))
    }

    /// 성공 응답인데 `data`가 비었으면 서버 계약 위반이다. CoreNetwork가 `decodingError`로 돌려준다.
    @Test func 응답에_data가_없으면_unknown을_돌려준다() async {
        let repository = SettingRepository.live(service: FakeAPIService(.json(#"{"success": true, "data": null}"#)))

        await #expect(throws: DomainError.unknown) {
            try await repository.fetchSetting().get()
        }
    }

    @Test func 통신_에러는_Domain_에러로_바꿔_돌려준다() async {
        let repository = SettingRepository.live(service: FakeAPIService(.failure(APIError.networkError("offline"))))

        await #expect(throws: DomainError.offline) {
            try await repository.fetchSetting().get()
        }
    }

    @Test func 요청이_취소되면_cancelled를_돌려준다() async {
        let repository = SettingRepository.live(service: FakeAPIService(.failure(APIError.cancelled)))

        await #expect(throws: DomainError.cancelled) {
            try await repository.fetchSetting().get()
        }
    }
}
