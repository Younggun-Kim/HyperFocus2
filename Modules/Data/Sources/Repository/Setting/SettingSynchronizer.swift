import CoreNetwork
import Domain

/// 기기에 남긴 설정을 기준으로 두고 서버와 맞춘다.
///
/// - 바꾼 값은 먼저 기기에 쓰고 구독자에게 보낸 뒤 서버에 보낸다. 보내지 못하면 표시해 두고 다음 동기화에서 보낸다.
/// - 서버 요청은 한 번에 하나씩 보낸다. 앞선 요청이 늦게 끝나 서버에 옛 값이 남지 않게 한다.
/// - 요청을 기다리는 동안 기기에서 값이 바뀌었으면 받은 서버 값을 버리고 다시 맞춘다.
actor SettingSynchronizer {
    private typealias Record = SettingLocalStore.Record

    private let service: any APIServiceProtocol
    private let store: SettingLocalStore
    private let broadcaster: CurrentValueBroadcaster<AppSetting>
    /// 기기 값이 바뀔 때마다 올린다. 요청 전후로 비교해 그 사이의 변경을 알아챈다.
    private var revision = 0
    /// 마지막으로 줄 세운 서버 요청.
    private var lastRequest: Task<Void, Never>?

    init(service: any APIServiceProtocol, store: SettingLocalStore) {
        self.service = service
        self.store = store
        self.broadcaster = CurrentValueBroadcaster(store.load()?.setting ?? .default)
    }

    nonisolated func observe() -> AsyncStream<AppSetting> {
        broadcaster.stream()
    }

    func update(_ setting: AppSetting) async -> Result<Void, DomainError> {
        var record = store.load() ?? Record(.default, accountId: nil, hasPendingChange: false)
        record.setting = setting
        record.hasPendingChange = true
        apply(record)

        // 아직 계정과 맞춘 적이 없으면 첫 동기화에서 보낸다.
        if let accountId = record.accountId {
            // 서버에 보내지 못해도 변경은 기기에 남아 있으므로 실패가 아니다. 원본은 Data가 로깅했다.
            _ = await sync(accountId: accountId)
        }
        return .success(())
    }

    func sync(accountId: String) async -> Result<AppSetting, DomainError> {
        let previous = lastRequest
        // 이 Task는 actor를 물려받아 `performSync`를 actor 안에서 실행한다.
        // 부른 쪽이 취소돼도 보내던 변경은 끝까지 보낸다.
        let request = Task {
            await previous?.value
            return await performSync(accountId: accountId)
        }
        lastRequest = Task { _ = await request.value }
        return await request.value
    }

    // MARK: - 동기화

    private func performSync(accountId: String) async -> Result<AppSetting, DomainError> {
        var record = store.load()
        if let owner = record?.accountId, owner != accountId {
            // 다른 계정의 값이다. 섞이지 않게 버리고 이 계정의 서버 값을 받는다.
            store.remove()
            record = nil
            revision += 1
            broadcaster.send(.default)
        }

        let startRevision = revision
        let result: Result<AppSetting, DomainError>
        if let record, record.hasPendingChange {
            result = await service.request(SettingAPI.Update(request: SettingRequestDTO(record.setting)))
                .domainResult("설정 변경")
                .map { $0.toEntity() }
        } else {
            result = await service.request(SettingAPI.Fetch())
                .domainResult("설정 조회")
                .map { $0.toEntity() }
        }

        guard case let .success(serverSetting) = result else { return result }
        guard revision == startRevision else {
            // 기다리는 동안 기기 값이 바뀌었다. 받은 값은 이미 옛 값이므로 바뀐 값으로 다시 맞춘다.
            return await performSync(accountId: accountId)
        }
        apply(Record(serverSetting, accountId: accountId, hasPendingChange: false))
        return .success(serverSetting)
    }

    /// 기기에 쓰고 구독자에게 보낸다.
    private func apply(_ record: Record) {
        store.save(record)
        revision += 1
        broadcaster.send(record.setting)
    }
}
