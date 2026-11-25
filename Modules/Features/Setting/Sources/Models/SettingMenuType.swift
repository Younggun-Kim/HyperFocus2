//
//  SettingMenuType.swift
//  Setting
//
//  Created by 김영건 on 11/25/26.
//

import DesignSystem
import Foundation
import SwiftUI

/// 설정 화면의 메뉴 한 줄. 섹션별 항목을 연관값으로 가진다.
public enum SettingMenuType: Equatable {
    case device(DeviceSetting)
    case aboutUs(AboutUs)

    public enum DeviceSetting: CaseIterable, Sendable {
        case sound
        case haptic
        case alarm
    }

    public enum AboutUs: CaseIterable, Sendable {
        case privacyPolicy
        case termsOfService
        case talkToDeveloper
    }
}

extension SettingMenuType {
    var icon: Image {
        switch self {
        case let .device(item): return item.icon
        case let .aboutUs(item): return item.icon
        }
    }

    var title: String {
        switch self {
        case let .device(item): return item.title
        case let .aboutUs(item): return item.title
        }
    }
}

extension SettingMenuType.DeviceSetting {
    var icon: Image {
        switch self {
        case .sound: return Image(systemName: "speaker.wave.2.fill")
        case .haptic: return DesignSystemAsset.icPhoneWaves.swiftUIImage
        case .alarm: return Image(systemName: "alarm")
        }
    }

    var title: String {
        switch self {
        case .sound: return "Sound"
        case .haptic: return "Haptic"
        case .alarm: return "Alarm"
        }
    }
}

extension SettingMenuType.AboutUs {
    var icon: Image {
        switch self {
        case .privacyPolicy: return Image(systemName: "figure.2")
        case .termsOfService: return Image(systemName: "book.circle")
        case .talkToDeveloper: return Image(systemName: "paperplane.fill")
        }
    }

    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        case .talkToDeveloper: return "Talk to Developer"
        }
    }
}
