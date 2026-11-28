import Domain
import Foundation
import os

/// 기기 설정을 UserDefaults에 남긴다. `SettingRepository`의 기준값이다.
struct SettingLocalStore: Sendable {
    /// 저장하는 한 덩어리. 값과 함께 어느 계정의 값인지, 서버에 보내지 못한 변경이 있는지 남긴다.
    struct Record: Codable, Equatable, Sendable {
        var soundEnabled: Bool
        var hapticEnabled: Bool
        var alarmEnabled: Bool
        /// 이 값을 서버와 맞춘 계정. 한 번도 맞추지 않았으면 nil이다.
        var accountId: String?
        /// 기기에서 바꾸고 아직 서버에 보내지 못했다.
        var hasPendingChange: Bool
    }

    /// UserDefaults는 여러 스레드에서 써도 안전하다(Apple 문서). SDK가 아직 `Sendable`로 표시하지 않았다.
    nonisolated(unsafe) private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "setting.local.v1") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> Record? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(Record.self, from: data)
        } catch {
            // 읽지 못하는 값은 없는 것으로 본다. 다음 동기화에서 서버 값으로 다시 채운다.
            Logger.data.error("설정 읽기 실패: \(String(describing: error))")
            return nil
        }
    }

    func save(_ record: Record) {
        do {
            defaults.set(try JSONEncoder().encode(record), forKey: key)
        } catch {
            Logger.data.error("설정 저장 실패: \(String(describing: error))")
        }
    }

    func remove() {
        defaults.removeObject(forKey: key)
    }
}

extension SettingLocalStore.Record {
    init(_ setting: AppSetting, accountId: String?, hasPendingChange: Bool) {
        self.init(
            soundEnabled: setting.soundEnabled,
            hapticEnabled: setting.hapticEnabled,
            alarmEnabled: setting.alarmEnabled,
            accountId: accountId,
            hasPendingChange: hasPendingChange
        )
    }

    var setting: AppSetting {
        get { AppSetting(soundEnabled: soundEnabled, hapticEnabled: hapticEnabled, alarmEnabled: alarmEnabled) }
        set {
            soundEnabled = newValue.soundEnabled
            hapticEnabled = newValue.hapticEnabled
            alarmEnabled = newValue.alarmEnabled
        }
    }
}
