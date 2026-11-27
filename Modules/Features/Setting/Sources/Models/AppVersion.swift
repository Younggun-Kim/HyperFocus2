import Foundation

/// 설치된 앱의 버전. 설정 화면 맨 아래에 보여 준다.
enum AppVersion {
    /// `1.2.0 (34)`처럼 버전과 빌드 번호를 함께 쓴다. 읽지 못한 값은 `?`로 둔다.
    static func display(bundle: Bundle = .main) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }
}
