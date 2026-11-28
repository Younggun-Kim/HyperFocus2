//
//  CommonInputFieldStyle.swift
//  DesignSystem
//
//  Created by 김영건 on 11/28/26.
//

import SwiftUI

public enum CommonInputFieldStyle {
    /// 한 줄 입력. 높이 56, 회색 배경
    case singleLine
    /// 여러 줄 입력. 높이 106, 반투명 배경과 안쪽 그림자
    case multiLine
}

extension CommonInputFieldStyle {
    var height: CGFloat {
        switch self {
        case .singleLine: 56
        case .multiLine: 106
        }
    }

    var textFontSize: CGFloat {
        switch self {
        case .singleLine: 17
        case .multiLine: 24
        }
    }

    var placeholderColor: Color {
        switch self {
        case .singleLine: DesignSystemAsset.Colors.systemGray.swiftUIColor
        case .multiLine: DesignSystemAsset.Colors.whiteFix.swiftUIColor
        }
    }

    @ViewBuilder
    var background: some View {
        let shape = RoundedRectangle(cornerRadius: 16)

        switch self {
        case .singleLine:
            shape.fill(DesignSystemAsset.Colors.systemLightGray.swiftUIColor)
        case .multiLine:
            shape.fill(
                Color(red: 240 / 255, green: 245 / 255, blue: 255 / 255, opacity: 0.3)
                    .shadow(.inner(color: .black.opacity(0.1), radius: 4, x: 0, y: 4))
                    .shadow(.inner(color: .white.opacity(0.8), radius: 2, x: 0, y: -2))
            )
        }
    }
}

struct CommonInputFieldAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Add")
                .font(.system(size: 13, weight: .bold))
                .tracking(-0.08)
                .foregroundStyle(DesignSystemAsset.Colors.systemBlue.swiftUIColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignSystemAsset.Colors.systemBlue.swiftUIColor.opacity(0.2))
                )
        }
        .buttonStyle(.plain)
    }
}
