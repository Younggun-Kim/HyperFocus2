import CoreNetwork
import Dependencies
import Domain

// Domain의 포트에 live 구현을 붙인다.
// Feature는 이 파일을 참조하지 않으므로, 정적 링크에서 빠지지 않도록 `DataModule.bootstrap()`이 직접 참조한다.
extension SettingRepository: @retroactive DependencyKey {
    public static let liveValue = live(service: DataNetwork.service, store: SettingLocalStore())

    /// 테스트가 가짜 `APIServiceProtocol`과 따로 만든 저장소를 넣을 수 있도록 인자로 받는다.
    /// 동기화 상태(진행 중인 요청, 구독자)를 함께 써야 하므로 한 번 만든 값을 계속 쓴다.
    static func live(service: any APIServiceProtocol, store: SettingLocalStore) -> Self {
        let synchronizer = SettingSynchronizer(service: service, store: store)
        return Self(
            observeSetting: { synchronizer.observe() },
            updateSetting: { await synchronizer.update($0) },
            syncSetting: { await synchronizer.sync(accountId: $0) }
        )
    }
}
