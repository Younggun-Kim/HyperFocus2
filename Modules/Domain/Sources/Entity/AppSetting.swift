/// 기기 동작 설정(사운드, 햅틱, 알람). 서버가 기준값을 가진다.
///
/// 계정마다 하나뿐인 값이라 `Identifiable`을 채택하지 않는다.
public struct AppSetting: Sendable, Equatable {
    public var soundEnabled: Bool
    public var hapticEnabled: Bool
    public var alarmEnabled: Bool

    public init(soundEnabled: Bool, hapticEnabled: Bool, alarmEnabled: Bool) {
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
        self.alarmEnabled = alarmEnabled
    }
}

extension AppSetting {
    /// 서버 값을 받기 전에 화면이 쓰는 값
    public static let `default` = AppSetting(soundEnabled: false, hapticEnabled: false, alarmEnabled: false)
}
