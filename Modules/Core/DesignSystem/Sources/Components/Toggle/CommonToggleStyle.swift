//
//  CommonToggleStyle.swift
//  DesignSystem
//
//  Created by 김영건 on 11/24/26.
//

import Foundation
import SwiftUI

struct CommonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(
                configuration.isOn
                ? DesignSystemAsset.Colors.systemBlue.swiftUIColor
                : DesignSystemAsset.Colors.labelVibrantTertiary.swiftUIColor
            )
            .frame(width: 64, height: 28)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(DesignSystemAsset.Colors.bgPrimary.swiftUIColor)
                    .frame(width: 39, height: 24)
                    .padding(2)
            }
            .animation(.snappy(duration: 0.2), value: configuration.isOn)
            .onTapGesture { configuration.isOn.toggle() }
    }
}
