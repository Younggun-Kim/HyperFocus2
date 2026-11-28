//
//  CommonChipStyle.swift
//  DesignSystem
//
//  Created by 김영건 on 11/28/26.
//

import SwiftUI

/// 꺼져 있을 때의 칩 모양. 켜지면 모두 선택(`systemBlue`) 모양이 된다.
public enum CommonChipStyle {
    /// 회색으로 채운 칩
    case `default`
    /// 테두리만 있는 칩
    case line
}

public enum CommonChipSize {
    case small
    case medium
    case large

    var fontSize: CGFloat {
        switch self {
        case .small: 13
        case .medium: 17
        case .large: 24
        }
    }

    var selectedWeight: Font.Weight {
        switch self {
        case .medium: .semibold
        case .small, .large: .bold
        }
    }
}

struct CommonChipToggleStyle: ToggleStyle {
    let style: CommonChipStyle
    let size: CommonChipSize

    func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn

        configuration.label
            .font(.system(size: size.fontSize, weight: isOn ? size.selectedWeight : .regular))
            .tracking(-0.08)
            .lineLimit(1)
            .foregroundStyle(foregroundColor(isOn: isOn))
            .padding(.horizontal, isOn ? 13 : 10)
            .padding(.vertical, isOn ? 8 : 5)
            .background { background(isOn: isOn) }
            .contentShape(Capsule())
            .animation(.snappy(duration: 0.2), value: isOn)
            .onTapGesture { configuration.isOn.toggle() }
    }

    private func foregroundColor(isOn: Bool) -> Color {
        if isOn || style == .default {
            return DesignSystemAsset.Colors.blackFix.swiftUIColor
        }
        return DesignSystemAsset.Colors.systemGray.swiftUIColor
    }

    @ViewBuilder
    private func background(isOn: Bool) -> some View {
        if isOn {
            Capsule()
                .fill(
                    DesignSystemAsset.Colors.systemBlue.swiftUIColor
                        .shadow(.inner(color: .black.opacity(0.1), radius: 2, x: 2, y: 2))
                )
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 2)
        } else {
            switch style {
            case .default:
                Capsule()
                    .fill(DesignSystemAsset.Colors.systemGray.swiftUIColor)
            case .line:
                Capsule()
                    .strokeBorder(DesignSystemAsset.Colors.systemLightGray.swiftUIColor, lineWidth: 1)
            }
        }
    }
}
