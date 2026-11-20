import Foundation

public enum TimeFormatter {
    /// 초 단위 시간을 `mm:ss` 형식의 문자열로 바꾼다.
    ///
    /// - 60분을 넘으면 분이 그대로 늘어난다. (예: 5400초 → `90:00`)
    /// - 음수는 0으로 취급한다.
    public static func minuteSecond(from seconds: Int) -> String {
        let clamped = max(seconds, 0)
        let minutes = clamped / 60
        let remainingSeconds = clamped % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
