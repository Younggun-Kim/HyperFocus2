import Domain
import Foundation
import os

struct AppVersionCheckRequestDTO: Encodable, Sendable, Equatable {
    let platform: String
    let currentVersion: String

    init(currentVersion: String) {
        self.platform = "ios"
        self.currentVersion = currentVersion
    }
}

/// 서버는 버전 정보를 더 보내지만, 앱이 쓰는 값만 받는다.
struct AppVersionCheckResponseDTO: Decodable, Sendable, Equatable {
    /// `NONE`, `OPTIONAL`, `REQUIRED`
    let updateType: String
    let storeUrl: String?
}

extension AppVersionCheckResponseDTO {
    func toEntity() -> AppUpdate {
        AppUpdate(policy: policy, storeURL: storeUrl.flatMap(URL.init(string:)))
    }

    /// 모르는 값이면 막지 않는다. 버전 체크는 진입을 돕는 기능이지 관문이 아니다.
    private var policy: AppUpdate.Policy {
        switch updateType.trimmingCharacters(in: .whitespaces).uppercased() {
        case "OPTIONAL": return .optional
        case "REQUIRED": return .required
        case "NONE": return .upToDate
        default:
            Logger.data.error("버전 체크: 모르는 updateType \(updateType)")
            return .upToDate
        }
    }
}
