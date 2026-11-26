import Domain

struct SettingRequestDTO: Encodable, Sendable, Equatable {
    let soundEnabled: Bool
    let hapticEnabled: Bool
    let alarmEnabled: Bool

    init(_ setting: AppSetting) {
        soundEnabled = setting.soundEnabled
        hapticEnabled = setting.hapticEnabled
        alarmEnabled = setting.alarmEnabled
    }
}

struct SettingResponseDTO: Decodable, Sendable, Equatable {
    let soundEnabled: Bool
    let hapticEnabled: Bool
    let alarmEnabled: Bool
}

extension SettingResponseDTO {
    func toEntity() -> AppSetting {
        AppSetting(soundEnabled: soundEnabled, hapticEnabled: hapticEnabled, alarmEnabled: alarmEnabled)
    }
}
