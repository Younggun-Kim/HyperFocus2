import CoreNetwork
import Foundation
import os

/// Data의 Repository가 함께 쓰는 통신 객체. 앱 전체에서 하나만 만든다.
enum DataNetwork {
    /// 처음 쓰는 순간(`DataModule.bootstrap()`이 Repository `liveValue`를 참조할 때) 만든다.
    static let service: any APIServiceProtocol = APIService(baseURL: apiBaseURL, tokenManager: tokenManager)

    /// 로그인한 Repository가 새 토큰을 넣는 곳. 키체인과 인터셉터의 메모리 토큰을 함께 바꾼다.
    static let tokenManager: TokenManager = {
        TokenManager(
            storage: KeychainTokenStorage(),
            refresh: { token in
                // refresh는 요청이 401을 받은 뒤에만 불리므로, 이때 `service`는 이미 만들어져 있다.
                await DataNetwork.service.request(
                    AuthAPI.Refresh(refreshToken: token.refreshToken)
                ).map { $0.toAuthToken() }
            },
            onSessionExpired: {
                Logger.data.notice("세션 만료: refresh token이 거절됐다")
                // `AuthRepository.sessionExpired` → `ObserveSessionExpiredUseCase` → RootFeature로 간다.
                sessionExpiry.notify()
            }
        )
    }()

    /// 세션 만료를 받는 곳. `TokenManager`가 만료를 알리면 구독 중인 스트림에 모두 흐른다.
    static let sessionExpiry = SessionExpiryBroadcaster()

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

/// Repository가 토큰을 읽고 바꾸는 창구. 테스트가 `TokenManager` 없이 가짜를 넣을 수 있게 함수로 둔다.
struct TokenAccess: Sendable {
    var current: @Sendable () -> AuthToken?
    var update: @Sendable (AuthToken?) -> Void
}

extension TokenAccess {
    static func manager(_ manager: TokenManager) -> Self {
        Self(current: { manager.token }, update: { manager.update($0) })
    }
}

extension Logger {
    /// Data 모듈 공통 로거. subsystem은 번들 ID, category는 모듈 이름
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hyperfocus.timer", category: "Data")
}
