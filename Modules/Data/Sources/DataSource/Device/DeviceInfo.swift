import Foundation

/// 피드백에 함께 보내는 기기 정보
struct DeviceInfo: Sendable, Equatable {
    let appVersion: String?
    let deviceModel: String?
    let osVersion: String?
}

extension DeviceInfo {
    static var current: DeviceInfo {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return DeviceInfo(
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            deviceModel: modelIdentifier,
            osVersion: "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        )
    }

    /// `iPhone17,1` 같은 기종 식별자. 시뮬레이터는 흉내 내는 기종을 돌려준다.
    private static var modelIdentifier: String? {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
        return identifier.isEmpty ? nil : identifier
    }
}
