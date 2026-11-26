import CoreNetwork
import Dependencies
import Domain
import os


extension SettingRepository: @retroactive DependencyKey {
    public static let liveValue = live(service: DataNetwork.service)
    
    static func live(service: any APIServiceProtocol) -> Self {
        Self(
            fetchSetting: {
                try await convertingErrors("설정 조회") {
                    let response = try await service.request(
                        SettingAPI.fetch,
                        responseType: SettingResponseDTO.self
                    )
                    return try requireData(response.data, "설정 조회").toEntity()
                }
            },
            updateSetting: { setting in
                try await convertingErrors("설정 변경") {
                    let response = try await service.request(
                        SettingAPI.update(SettingRequestDTO(setting)),
                        responseType: SettingResponseDTO.self
                    )
                    return try requireData(response.data, "설정 변경").toEntity()
                }
            }
        )
    }
}

private func requireData<T>(_ data: T?, _ operation: String) throws -> T {
    guard let data else {
        Logger.data.error("\(operation) 응답에 data가 없다")
        throw DomainError.notFound
    }
    return data
}
