import Dependencies
import Domain
import Testing

/// UseCase는 지금 Repository에 위임만 한다. 위임이 끊기지 않았는지(값과 에러를 그대로 넘기는지) 확인한다.
struct SettingUseCaseTests {
    private let stored = AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: true)

    @Test func 설정을_불러오면_저장소의_값을_돌려준다() async throws {
        let setting = try await withDependencies {
            $0.settingRepository.fetchSetting = { [stored] in .success(stored) }
        } operation: {
            try await FetchSettingUseCase.liveValue.execute().get()
        }

        #expect(setting == stored)
    }

    @Test func 설정을_저장하면_저장소가_확정한_값을_돌려준다() async throws {
        let received = LockIsolated<AppSetting?>(nil)
        let confirmed = AppSetting(soundEnabled: false, hapticEnabled: false, alarmEnabled: false)

        let setting = try await withDependencies {
            $0.settingRepository.updateSetting = { setting in
                received.setValue(setting)
                return .success(confirmed)
            }
        } operation: {
            try await UpdateSettingUseCase.liveValue.execute(stored).get()
        }

        #expect(received.value == stored)
        #expect(setting == confirmed)
    }

    @Test func 저장소의_Domain_에러를_그대로_돌려준다() async {
        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.settingRepository.fetchSetting = { .failure(.offline) }
            } operation: {
                try await FetchSettingUseCase.liveValue.execute().get()
            }
        }
    }

    @Test func 피드백_전송은_카테고리와_내용을_저장소에_넘긴다() async throws {
        let received = LockIsolated<(FeedbackCategory, String)?>(nil)

        try await withDependencies {
            $0.feedbackRepository.sendFeedback = {
                received.setValue(($0, $1))
                return .success(())
            }
        } operation: {
            try await SendFeedbackUseCase.liveValue.execute(.bugReport, "버그").get()
        }

        #expect(received.value?.0 == .bugReport)
        #expect(received.value?.1 == "버그")
    }
}
