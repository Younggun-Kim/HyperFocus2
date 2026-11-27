import Foundation
import os

extension Logger {
    /// Setting 모듈 공통 로거. subsystem은 번들 ID, category는 모듈 이름
    static let setting = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hyperfocus.timer", category: "Setting")
}
