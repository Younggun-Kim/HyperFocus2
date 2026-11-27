import Domain

extension AppSetting {
    /// 메뉴 항목 하나로 읽고 쓰는 창구. 화면과 Reducer가 같은 매핑을 쓴다.
    subscript(type: SettingMenuType.DeviceSetting) -> Bool {
        get {
            switch type {
            case .sound: soundEnabled
            case .haptic: hapticEnabled
            case .alarm: alarmEnabled
            }
        }
        set {
            switch type {
            case .sound: soundEnabled = newValue
            case .haptic: hapticEnabled = newValue
            case .alarm: alarmEnabled = newValue
            }
        }
    }
}
