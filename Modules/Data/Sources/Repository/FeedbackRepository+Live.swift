import CoreNetwork
import Dependencies
import Domain

// Domain의 포트에 live 구현을 붙인다. `DataModule.bootstrap()`이 직접 참조해 링크와 등록을 보장한다.
extension FeedbackRepository: @retroactive DependencyKey {
    public static let liveValue = live(service: DataNetwork.service, device: { .current })

    /// - Parameter device: 보낼 때마다 읽는다(앱 업데이트 후에도 최신 값).
    static func live(
        service: any APIServiceProtocol,
        device: @escaping @Sendable () -> DeviceInfo
    ) -> Self {
        Self(
            sendFeedback: { category, content in
                let device = device()
                let request = FeedbackRequestDTO(
                    category: category.apiValue,
                    content: content,
                    appVersion: device.appVersion,
                    deviceModel: device.deviceModel,
                    osVersion: device.osVersion
                )
                _ = try await service.request(FeedbackAPI.Send(request: request))
                    .orThrowDomainError("피드백 전송")
            }
        )
    }
}
