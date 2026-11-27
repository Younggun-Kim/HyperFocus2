import CoreNetwork
import Dependencies
import Domain
import Foundation
import os

// Domain의 포트에 live 구현을 붙인다. `DataModule.bootstrap()`이 직접 참조해 링크와 등록을 보장한다.
extension AppVersionRepository: @retroactive DependencyKey {
    public static let liveValue = live(
        service: DataNetwork.service,
        currentVersion: { DeviceInfo.current.appVersion }
    )

    /// - Parameter currentVersion: 설치된 버전(`CFBundleShortVersionString`). 테스트가 바꿔 넣는다.
    static func live(
        service: any APIServiceProtocol,
        currentVersion: @escaping @Sendable () -> String?
    ) -> Self {
        Self(
            checkUpdate: {
                guard let version = currentVersion() else {
                    Logger.data.error("버전 체크 실패: 설치된 버전을 읽지 못했다")
                    return .failure(.unknown)
                }
                return await service.request(AppVersionAPI.Check(request: AppVersionCheckRequestDTO(currentVersion: version)))
                    .domainResult("버전 체크")
                    .map { $0.toEntity() }
            }
        )
    }
}
