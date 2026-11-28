/// 기기 동작 설정(사운드, 햅틱, 알람). 기기에 남긴 값이 기준이고, 서버와는 동기화한다.
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
    /// 기기에 저장된 값이 없을 때 쓰는 값. 처음 설치한 뒤 서버와 맞추기 전까지 쓰인다.
    /// 오프라인으로 처음 연 사용자도 집중이 끝난 것을 알 수 있게 모두 켠다.
    public static let `default` = AppSetting(soundEnabled: true, hapticEnabled: true, alarmEnabled: true)
}
