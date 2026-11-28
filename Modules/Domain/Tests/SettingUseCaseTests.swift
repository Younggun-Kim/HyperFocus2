import Dependencies
import Domain
import Testing

/// UseCase는 지금 Repository에 위임만 한다. 위임이 끊기지 않았는지(값과 에러를 그대로 넘기는지) 확인한다.
struct SettingUseCaseTests {
    private let stored = AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: true)

    @Test func 설정을_구독하면_저장소의_스트림을_그대로_넘긴다() async {
        let stream = withDependencies {
            $0.settingRepository.observeSetting = { [stored] in
                AsyncStream {
                    $0.yield(stored)
                    $0.finish()
                }
            }
        } operation: {
            ObserveSettingUseCase.liveValue.execute()
        }

        var received: [AppSetting] = []
        for await setting in stream {
            received.append(setting)
        }
        #expect(received == [stored])
    }

    @Test func 설정을_바꾸면_값을_저장소에_넘긴다() async throws {
        let received = LockIsolated<AppSetting?>(nil)

        try await withDependencies {
            $0.settingRepository.updateSetting = { setting in
                received.setValue(setting)
                return .success(())
            }
        } operation: {
            try await UpdateSettingUseCase.liveValue.execute(stored).get()
        }

        #expect(received.value == stored)
    }

    @Test func 동기화하면_계정을_저장소에_넘기고_맞춘_값을_돌려준다() async throws {
        let received = LockIsolated<String?>(nil)

        let setting = try await withDependencies {
            $0.settingRepository.syncSetting = { [stored] accountId in
                received.setValue(accountId)
                return .success(stored)
            }
        } operation: {
            try await SyncSettingUseCase.liveValue.execute("user-1").get()
        }

        #expect(received.value == "user-1")
        #expect(setting == stored)
    }

    @Test func 저장소의_Domain_에러를_그대로_돌려준다() async {
        await #expect(throws: DomainError.offline) {
            try await withDependencies {
                $0.settingRepository.syncSetting = { _ in .failure(.offline) }
            } operation: {
                try await SyncSettingUseCase.liveValue.execute("user-1").get()
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
