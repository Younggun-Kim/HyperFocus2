import CoreNetwork
import Dependencies
import Domain

// Domain의 포트에 live 구현을 붙인다.
// Feature는 이 파일을 참조하지 않으므로, 정적 링크에서 빠지지 않도록 `DataModule.bootstrap()`이 직접 참조한다.
extension SettingRepository: @retroactive DependencyKey {
    public static let liveValue = live(service: DataNetwork.service)

    /// 테스트가 가짜 `APIServiceProtocol`을 넣을 수 있도록 통신 객체를 인자로 받는다.
    static func live(service: any APIServiceProtocol) -> Self {
        Self(
            fetchSetting: {
                try await service.request(SettingAPI.Fetch())
                    .orThrowDomainError("설정 조회")
                    .toEntity()
            },
            updateSetting: { setting in
                try await service.request(SettingAPI.Update(request: SettingRequestDTO(setting)))
                    .orThrowDomainError("설정 변경")
                    .toEntity()
            }
        )
    }
}
