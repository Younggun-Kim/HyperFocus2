import DesignSystem
import SwiftUI
import Testing
@testable import Setting

struct SettingMenuTypeTests {
    @Test(arguments: [
        (SettingMenuType.device(.sound), "Sound"),
        (.device(.haptic), "Haptic"),
        (.device(.alarm), "Alarm"),
        (.aboutUs(.privacyPolicy), "Privacy Policy"),
        (.aboutUs(.termsOfService), "Terms of Service"),
        (.aboutUs(.talkToDeveloper), "Talk to Developer"),
    ])
    func 항목별_제목을_보여준다(type: SettingMenuType, expected: String) {
        #expect(type.title == expected)
    }

    @Test(arguments: [
        (SettingMenuType.device(.sound), Image(systemName: "speaker.wave.2.fill")),
        (.device(.haptic), DesignSystemAsset.Assets.icPhoneWaves.swiftUIImage),
        (.device(.alarm), Image(systemName: "alarm")),
        (.aboutUs(.privacyPolicy), Image(systemName: "figure.2")),
        (.aboutUs(.termsOfService), Image(systemName: "book.circle")),
        (.aboutUs(.talkToDeveloper), Image(systemName: "paperplane.fill")),
    ])
    func 항목별_아이콘을_보여준다(type: SettingMenuType, expected: Image) {
        #expect(type.icon == expected)
    }

    @Test func 모든_항목의_제목이_다르다() {
        let titles = SettingMenuType.DeviceSetting.allCases.map { SettingMenuType.device($0).title }
            + SettingMenuType.AboutUs.allCases.map { SettingMenuType.aboutUs($0).title }

        #expect(Set(titles).count == titles.count)
    }
}
