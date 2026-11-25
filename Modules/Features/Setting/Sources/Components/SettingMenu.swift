//
//  SettingMenu.swift
//  Setting
//
//  Created by 김영건 on 11/24/26.
//

import DesignSystem
import Foundation
import SwiftUI

struct SettingMenu<Accessory: View>: View {
    private let type: SettingMenuType
    private let accessory: Accessory
    
    init(type: SettingMenuType, @ViewBuilder accessory: () -> Accessory) {
        self.type = type
        self.accessory = accessory()
    }
    
    var body: some View {
        HStack(spacing: 10) {
            type.icon
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    DesignSystemAsset.Colors.systemLightGray.swiftUIColor,
                    in: .rect(cornerRadius: 8)
                )
                .accessibilityHidden(true)
            
            Text(type.title)
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.08)
                .foregroundStyle(.white)
            
            Spacer()
            
            accessory
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    @Previewable @State var isOn = true
    
    VStack(spacing: 16) {
        SettingMenu(type: .device(.sound)) {
            CommonToggle(isOn: $isOn)
        }
        
        Button {} label: {
            SettingMenu(type: .aboutUs(.privacyPolicy)) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
    }
    .padding()
    .background(Color.black)
}
