//
//  SettingRow.swift
//  Setting
//
//  Created by 김영건 on 11/24/26.
//

import DesignSystem
import Foundation
import SwiftUI

/// 아이콘, 제목, 오른쪽 요소로 이루어진 설정 한 줄.
/// 레이아웃만 맡는다. 토글·탭 같은 동작은 호출하는 쪽에서 `accessory`나 감싸는 `Button`으로 붙인다.
struct SettingRow<Accessory: View>: View {
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
                    Color(red: 118 / 255, green: 118 / 255, blue: 128 / 255, opacity: 0.3),
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
        SettingRow(type: .device(.sound)) {
            CommonToggle(isOn: $isOn)
        }

        Button {} label: {
            SettingRow(type: .aboutUs(.privacyPolicy)) {
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
