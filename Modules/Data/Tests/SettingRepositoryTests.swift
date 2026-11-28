import CoreNetwork
import Domain
import Foundation
import Testing
@testable import Data

struct SettingRepositoryTests {
    private let serverJSON = #"{"success": true, "data": {"soundEnabled": true, "hapticEnabled": false, "alarmEnabled": true}}"#
    private let server = AppSetting(soundEnabled: true, hapticEnabled: false, alarmEnabled: true)
    private let edited = AppSetting(soundEnabled: false, hapticEnabled: true, alarmEnabled: false)

    /// 테스트마다 따로 쓰는 UserDefaults. 다른 테스트나 앱의 값과 섞이지 않는다.
    private let store = SettingLocalStore(defaults: UserDefaults(suiteName: "SettingRepositoryTests.\(UUID().uuidString)")!)

    private func makeRepository(_ replies: FakeAPIService.Reply...) -> (SettingRepository, FakeAPIService) {
        let service = FakeAPIService(replies.isEmpty ? [.failure(.unknown("요청하지 않아야 한다"))] : replies)
        return (SettingRepository.live(service: service, store: store), service)
    }

    private func firstValue(of repository: SettingRepository) async -> AppSetting? {
        var iterator = repository.observeSetting().makeAsyncIterator()
        return await iterator.next()
    }

    // MARK: - 구독

    @Test func 저장된_값이_없으면_기본값을_보낸다() async {
        let (repository, _) = makeRepository()

        #expect(await firstValue(of: repository) == .default)
    }

    @Test func 구독하면_지금_값을_먼저_보내고_바뀔_때마다_보낸다() async throws {
        let (repository, _) = makeRepository()
        var iterator = repository.observeSetting().makeAsyncIterator()
        #expect(await iterator.next() == .default)

        try await repository.updateSetting(edited).get()

        #expect(await iterator.next() == edited)
    }

    // MARK: - 변경

    @Test func 계정과_맞춘_적이_없으면_기기에만_쓰고_요청하지_않는다() async throws {
        let (repository, service) = makeRepository()

        try await repository.updateSetting(edited).get()

        #expect(service.endpoints.isEmpty)
        #expect(store.load() == .init(edited, accountId: nil, hasPendingChange: true))
    }

    @Test func 계정이_있으면_바꾼_전체_값을_PATCH로_보내고_서버_값을_남긴다() async throws {
        store.save(.init(server, accountId: "user-1", hasPendingChange: false))
        let (repository, service) = makeRepository(.json(serverJSON))

        try await repository.updateSetting(edited).get()

        let endpoint = try #require(service.endpoints.first as? SettingAPI.Update)
        #expect(endpoint.request == SettingRequestDTO(edited))
        #expect(store.load() == .init(server, accountId: "user-1", hasPendingChange: false))
    }

    @Test func 서버에_보내지_못해도_변경은_성공이고_보낼_것으로_남긴다() async throws {
        store.save(.init(server, accountId: "user-1", hasPendingChange: false))
        let (repository, _) = makeRepository(.failure(.networkError("offline")))

        try await repository.updateSetting(edited).get()

        #expect(store.load() == .init(edited, accountId: "user-1", hasPendingChange: true))
        #expect(await firstValue(of: repository) == edited)
    }

    // MARK: - 동기화

    @Test func 보낼_변경이_없으면_서버_값을_받아_기기에_남긴다() async throws {
        let (repository, service) = makeRepository(.json(serverJSON))

        let setting = try await repository.syncSetting("user-1").get()

        #expect(setting == server)
        #expect(service.endpoints.first is SettingAPI.Fetch)
        #expect(store.load() == .init(server, accountId: "user-1", hasPendingChange: false))
    }

    @Test func 받아_둔_값은_앱을_다시_열어도_남아_있다() async throws {
        let (repository, _) = makeRepository(.json(serverJSON))
        _ = try await repository.syncSetting("user-1").get()

        let (reopened, _) = makeRepository()

        #expect(await firstValue(of: reopened) == server)
    }

    @Test func 계정과_맞추기_전에_바꾼_값은_첫_동기화에서_보낸다() async throws {
        let (repository, service) = makeRepository(.json(serverJSON))
        try await repository.updateSetting(edited).get()

        _ = try await repository.syncSetting("user-1").get()

        let endpoint = try #require(service.endpoints.first as? SettingAPI.Update)
        #expect(endpoint.request == SettingRequestDTO(edited))
        #expect(store.load()?.hasPendingChange == false)
    }

    @Test func 오프라인에서_바꾼_값은_다음_동기화에서_보낸다() async throws {
        store.save(.init(server, accountId: "user-1", hasPendingChange: false))
        let (repository, service) = makeRepository(.failure(.networkError("offline")), .json(serverJSON))
        try await repository.updateSetting(edited).get()

        _ = try await repository.syncSetting("user-1").get()

        #expect(service.endpoints.count == 2)
        let retried = try #require(service.endpoints.last as? SettingAPI.Update)
        #expect(retried.request == SettingRequestDTO(edited))
        #expect(store.load()?.hasPendingChange == false)
    }

    @Test func 다른_계정의_값은_보내지_않고_버린_뒤_서버_값을_받는다() async throws {
        store.save(.init(edited, accountId: "old-user", hasPendingChange: true))
        let (repository, service) = makeRepository(.json(serverJSON))

        let setting = try await repository.syncSetting("new-user").get()

        #expect(service.endpoints.count == 1)
        #expect(service.endpoints.first is SettingAPI.Fetch)
        #expect(setting == server)
        #expect(store.load() == .init(server, accountId: "new-user", hasPendingChange: false))
    }

    @Test func 다른_계정의_값은_서버에_닿지_못해도_남기지_않는다() async {
        store.save(.init(edited, accountId: "old-user", hasPendingChange: false))
        let (repository, _) = makeRepository(.failure(.networkError("offline")))

        _ = await repository.syncSetting("new-user")

        #expect(store.load() == nil)
        #expect(await firstValue(of: repository) == .default)
    }

    // MARK: - 에러

    @Test func 통신_에러는_Domain_에러로_바꾸고_기기_값은_그대로_둔다() async {
        store.save(.init(edited, accountId: "user-1", hasPendingChange: false))
        let (repository, _) = makeRepository(.failure(.networkError("offline")))

        await #expect(throws: DomainError.offline) {
            try await repository.syncSetting("user-1").get()
        }
        #expect(store.load() == .init(edited, accountId: "user-1", hasPendingChange: false))
    }

    /// 성공 응답인데 `data`가 비었으면 서버 계약 위반이다. CoreNetwork가 `decodingError`로 돌려준다.
    @Test func 응답에_data가_없으면_unknown을_돌려준다() async {
        let (repository, _) = makeRepository(.json(#"{"success": true, "data": null}"#))

        await #expect(throws: DomainError.unknown) {
            try await repository.syncSetting("user-1").get()
        }
    }

    @Test func 요청이_취소되면_cancelled를_돌려준다() async {
        let (repository, _) = makeRepository(.failure(.cancelled))

        await #expect(throws: DomainError.cancelled) {
            try await repository.syncSetting("user-1").get()
        }
    }

    @Test func 저장된_값을_읽지_못하면_없는_것으로_본다() {
        let defaults = UserDefaults(suiteName: "SettingRepositoryTests.\(UUID().uuidString)")!
        defaults.set(Data("broken".utf8), forKey: "setting.local.v1")

        #expect(SettingLocalStore(defaults: defaults).load() == nil)
    }
}
