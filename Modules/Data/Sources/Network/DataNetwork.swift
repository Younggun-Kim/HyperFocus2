import CoreNetwork
import Foundation
import os

/// Data의 Repository가 함께 쓰는 통신 객체. 앱 전체에서 하나만 만든다.
enum DataNetwork {
    /// 처음 쓰는 순간(`DataModule.bootstrap()`이 Repository `liveValue`를 참조할 때) 만든다.
    static let service: any APIServiceProtocol = {
        let tokenManager = TokenManager(
            storage: KeychainTokenStorage(),
            refresh: { token in
                // refresh는 요청이 401을 받은 뒤에만 불리므로, 이때 `service`는 이미 만들어져 있다.
                let response = try await DataNetwork.service.request(
                    AuthEndpoint.refresh(refreshToken: token.refreshToken),
                    responseType: TokenResponseDTO.self
                )
                guard let data = response.data else {
                    throw APIError.decodingError("갱신 응답에 토큰이 없다")
                }
                return data.toAuthToken()
            },
            onSessionExpired: {
                // TODO: 세션 만료를 Domain UseCase로 내보내 RootFeature가 처리하게 한다(계정 기능 PR).
                Logger.data.notice("세션 만료: refresh token이 거절됐다")
            }
        )
        return APIService(baseURL: apiBaseURL, tokenManager: tokenManager)
    }()

    /// App의 xcconfig(`API_BASE_URL`) → Info.plist로 들어온 값
    static let apiBaseURL: URL = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
            let url = URL(string: value),
            url.host() != nil
        else {
            preconditionFailure("Info.plist의 API_BASE_URL이 비었거나 잘못됐다. App/Configs/*.xcconfig를 확인한다.")
        }
        return url
    }()
}

extension Logger {
    /// Data 모듈 공통 로거. subsystem은 번들 ID, category는 모듈 이름
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hyperfocus.timer", category: "Data")
}
