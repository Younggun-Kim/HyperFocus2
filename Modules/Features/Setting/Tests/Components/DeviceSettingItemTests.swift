import DesignSystem
import SwiftUI
import Testing
@testable import Setting

struct DeviceSettingItemTests {
    @Test(arguments: [
        (DeviceSettingItemType.sound, "Sound"),
        (.haptic, "Haptic"),
        (.alarm, "Alarm"),
    ])
    func 타입별_제목을_보여준다(type: DeviceSettingItemType, expected: String) {
        #expect(type.title == expected)
    }

    @Test(arguments: [
        (DeviceSettingItemType.sound, Image(systemName: "speaker.wave.2.fill")),
        (.haptic, DesignSystemAsset.icPhoneWaves.swiftUIImage),
        (.alarm, Image(systemName: "alarm")),
    ])
    func 타입별_아이콘을_보여준다(type: DeviceSettingItemType, expected: Image) {
        #expect(type.icon == expected)
    }

    @Test func 타입마다_제목이_다르다() {
        let titles = DeviceSettingItemType.allCases.map(\.title)

        #expect(Set(titles).count == titles.count)
    }
}
