import SwiftUI

/// `AmbientZStack` 배경의 색 조합.
public enum AmbientStyleType: String, Codable, Sendable, CaseIterable {
    case allBlack
    case all282828
    case all121619
    case input
    case white
    case blueDark
    case calmDark
    case withBuddy
}

/// 바탕색 위에 흐린 원 세 개(좌상단, 우상단, 우하단)를 올린 배경.
struct AmbientStyle {
    var baseColor: Color
    var topLeftColor: Color
    var topRightColor: Color
    var bottomRightColor: Color
    /// 세 원에 같이 적용하는 blur 반경
    var blur: CGFloat = 400
    /// 우상단 원의 가로 위치(화면 너비 대비 비율). 세로는 항상 화면 위쪽 끝이다.
    var topRightX: CGFloat = 0.9
    /// 우하단 원의 위치(화면 크기 대비 비율)
    var bottomRightPosition = UnitPoint(x: 0.9, y: 0.55)

    /// 원까지 모두 같은 색인 단색 배경
    static func solid(_ color: Color) -> Self {
        Self(baseColor: color, topLeftColor: color, topRightColor: color, bottomRightColor: color)
    }
}

extension AmbientStyleType {
    var style: AmbientStyle {
        switch self {
        case .allBlack:
                .solid(.black)
        case .all282828:
                .solid(Color(hex: 0x282828))
        case .all121619:
                .solid(Color(hex: 0x121619))
        case .input:
            AmbientStyle(
                baseColor: .black.opacity(0.7),
                topLeftColor: Color(hex: 0x203A43),
                topRightColor: Color(hex: 0x0F2027),
                bottomRightColor: Color(hex: 0x2C5364),
                blur: 200,
                bottomRightPosition: UnitPoint(x: 0.9, y: 0.8)
            )
        case .white:
            AmbientStyle(
                baseColor: .white.opacity(0.7),
                topLeftColor: Color(hex: 0x203A43),
                topRightColor: Color(hex: 0x0F2027),
                bottomRightColor: Color(hex: 0x2C5364),
                blur: 200,
                bottomRightPosition: UnitPoint(x: 0.9, y: 0.8)
            )
        case .blueDark:
            AmbientStyle(
                baseColor: .white,
                topLeftColor: Color(hex: 0xB8E4FF),
                topRightColor: Color(hex: 0x43FFC4),
                bottomRightColor: Color(hex: 0xAF78C9)
            )
        case .calmDark:
            AmbientStyle(
                baseColor: .black,
                topLeftColor: Color(hex: 0x6D9CB9),
                topRightColor: Color(hex: 0x0E7252),
                bottomRightColor: Color(hex: 0x343573),
                blur: 150,
                bottomRightPosition: UnitPoint(x: 0.85, y: 1)
            )
        case .withBuddy:
            AmbientStyle(
                baseColor: .black,
                topLeftColor: Color(hex: 0x3D1A5E),
                topRightColor: Color(hex: 0x1A0E3A),
                bottomRightColor: Color(hex: 0x6B1FA0),
                blur: 200,
                bottomRightPosition: UnitPoint(x: 0.85, y: 1)
            )
        }
    }
}

extension Color {
    /// `0xRRGGBB` 값으로 만든 불투명한 sRGB 색
    fileprivate init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
