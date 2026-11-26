import SwiftUI

/// 흐린 색 원으로 채운 배경 위에 내용을 올리는 ZStack. 화면 전체를 차지한다.
public struct AmbientZStack<Content: View>: View {
    private let style: AmbientStyle
    private let alignment: Alignment
    private let content: Content

    public init(
        style: AmbientStyleType,
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style.style
        self.alignment = alignment
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: alignment) {
                style.baseColor
                    .ignoresSafeArea()

                Circle()
                    .fill(style.topLeftColor)
                    .frame(width: 600, height: 600)
                    .blur(radius: style.blur)
                    .position(x: 0, y: 0)

                Circle()
                    .fill(style.topRightColor)
                    .frame(width: 600, height: 600)
                    .blur(radius: style.blur)
                    .position(x: geometry.size.width * style.topRightX, y: 0)

                Circle()
                    .fill(style.bottomRightColor)
                    .frame(width: 637, height: 637)
                    .blur(radius: style.blur)
                    .position(
                        x: geometry.size.width * style.bottomRightPosition.x,
                        y: geometry.size.height * style.bottomRightPosition.y
                    )

                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("black") {
    AmbientZStack(style: .black) {
        Text("HyperFocus")
            .font(.ComingSoon.largeTitle)
            .foregroundStyle(.white)
    }
}

#Preview("all121619") {
    AmbientZStack(style: .all121619) {
        DesignSystemAsset.Assets.splashLight.swiftUIImage
    }
}
