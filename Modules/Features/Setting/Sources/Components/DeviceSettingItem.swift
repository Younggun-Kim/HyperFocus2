//
//  DeviceSettingItem.swift
//  Setting
//
//  Created by 김영건 on 11/24/26.
//

import DesignSystem
import Foundation
import SwiftUI


public struct DeviceSettingItem: View {
    private let type: DeviceSettingItemType
    @Binding private var isOn: Bool
    
    public init(type: DeviceSettingItemType, isOn: Binding<Bool>) {
        self.type = type
        self._isOn = isOn
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            type.icon
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    Color(red: 118 / 255, green: 118 / 255, blue: 128 / 255, opacity: 0.3),
                    in: .rect(cornerRadius: 8)
                )
                .accessibilityHidden(true)
            
            Text(type.title)
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.08)
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            
            Spacer()
            
            CommonToggle(isOn: $isOn)
                .accessibilityLabel(type.title)
        }
    }
}


public enum DeviceSettingItemType: CaseIterable {
    case sound
    case haptic
    case alarm
}

extension DeviceSettingItemType{
    var icon: Image {
        switch self {
        case .sound:
            return Image(systemName: "speaker.wave.2.fill")
        case .haptic:
            return DesignSystemAsset.icPhoneWaves.swiftUIImage
        case .alarm:
            return Image(systemName: "alarm")
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

#Preview {
    @Previewable @State var isOn = true
    
    VStack(spacing: 16) {
        DeviceSettingItem(type: .sound, isOn: $isOn)
        DeviceSettingItem(type: .haptic, isOn: $isOn)
        DeviceSettingItem(type: .alarm, isOn: $isOn)
    }
    .padding()
    .background(Color.black)
}
