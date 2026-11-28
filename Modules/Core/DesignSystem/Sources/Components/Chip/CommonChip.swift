//
//  CommonChip.swift
//  DesignSystem
//
//  Created by 김영건 on 11/28/26.
//

import SwiftUI

public struct CommonChip: View {
    private let title: String
    private let style: CommonChipStyle
    private let size: CommonChipSize
    @Binding private var isOn: Bool

    public init(
        _ title: String,
        isOn: Binding<Bool>,
        style: CommonChipStyle = .default,
        size: CommonChipSize = .large
    ) {
        self.title = title
        self._isOn = isOn
        self.style = style
        self.size = size
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
        }
        .toggleStyle(CommonChipToggleStyle(style: style, size: size))
    }
}


#Preview {
    @Previewable @State var isOn = false

    VStack(spacing: 16) {
        ForEach([CommonChipStyle.default, .line], id: \.self) { style in
            HStack {
                CommonChip("Work", isOn: $isOn, style: style, size: .large)
                CommonChip("Work", isOn: $isOn, style: style, size: .medium)
                CommonChip("Work", isOn: $isOn, style: style, size: .small)
            }
        }
    }
    .padding()
    .background(Color(white: 0.17))
}
