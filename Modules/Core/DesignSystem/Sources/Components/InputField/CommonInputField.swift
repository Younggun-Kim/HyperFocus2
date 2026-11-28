//
//  CommonInputField.swift
//  DesignSystem
//
//  Created by 김영건 on 11/28/26.
//

import SwiftUI

public struct CommonInputField: View {
    @Binding private var text: String
    private let placeholder: String
    private let style: CommonInputFieldStyle
    private let onAdd: () -> Void

    public init(
        text: Binding<String>,
        placeholder: String,
        style: CommonInputFieldStyle = .singleLine,
        onAdd: @escaping () -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.onAdd = onAdd
    }

    public var body: some View {
        HStack(alignment: style == .singleLine ? .center : .top, spacing: 8) {
            textField
            CommonInputFieldAddButton(action: onAdd)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .frame(height: style.height, alignment: style == .singleLine ? .center : .top)
        .background { style.background }
    }

    @ViewBuilder
    private var textField: some View {
        switch style {
        case .singleLine:
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(style.placeholderColor)
            )
            .modifier(InputTextModifier(fontSize: style.textFontSize))
            .onSubmit(onAdd)
        case .multiLine:
            // TextField의 prompt는 한 줄로만 그려져서 여러 줄 안내 문구는 직접 겹쳐 그린다.
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 17))
                        .tracking(-0.08)
                        .foregroundStyle(style.placeholderColor)
                        .allowsHitTesting(false)
                }
                TextField("", text: $text, axis: .vertical)
                    .lineLimit(1...3)
                    .modifier(InputTextModifier(fontSize: style.textFontSize))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct InputTextModifier: ViewModifier {
    let fontSize: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize))
            .tracking(-0.08)
            .foregroundStyle(DesignSystemAsset.Colors.systemBlue.swiftUIColor)
            .tint(DesignSystemAsset.Colors.systemBlue.swiftUIColor)
    }
}


#Preview {
    @Previewable @State var task = ""
    @Previewable @State var oneThing = ""

    VStack(spacing: 20) {
        CommonInputField(text: $task, placeholder: "What to focus on?") {}
        CommonInputField(
            text: $oneThing,
            placeholder: "What’s your one thing today?\n(Optional)",
            style: .multiLine
        ) {}
    }
    .padding(24)
    .background(Color(white: 0.17))
}
