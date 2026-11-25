import CoreNetwork
import Dependencies
import Domain
import os

// Domain의 포트에 live 구현을 붙인다.
// Feature는 이 파일을 참조하지 않으므로, 정적 링크에서 빠지지 않도록 `DataModule.bootstrap()`이 직접 참조한다.
extension SettingRepository: @retroactive DependencyKey {
    public static let liveValue = live(service: DataNetwork.service)

    /// 테스트가 가짜 `APIServiceProtocol`을 넣을 수 있도록 통신 객체를 인자로 받는다.
    static func live(service: any APIServiceProtocol) -> Self {
        Self(
            fetchSetting: {
                try await convertingErrors("설정 조회") {
                    let response = try await service.request(SettingEndpoint.fetch, responseType: SettingResponseDTO.self)
                    return try requireData(response.data, "설정 조회").toEntity()
                }
            },
            updateSetting: { setting in
                try await convertingErrors("설정 변경") {
                    let response = try await service.request(
                        SettingEndpoint.update(SettingRequestDTO(setting)),
                        responseType: SettingResponseDTO.self
                    )
                    return try requireData(response.data, "설정 변경").toEntity()
                }
            }
        )
    }
}

/// 성공 응답인데 `data`가 비었으면 서버 계약 위반이다. 로깅하고 `notFound`로 올린다.
private func requireData<T>(_ data: T?, _ operation: String) throws -> T {
    guard let data else {
        Logger.data.error("\(operation) 응답에 data가 없다")
        throw DomainError.notFound
    }
    return data
}
