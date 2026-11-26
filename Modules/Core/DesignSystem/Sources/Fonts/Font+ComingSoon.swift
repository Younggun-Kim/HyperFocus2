import SwiftUI

extension Font {
    /// 앱 이름과 타이틀에 쓰는 손글씨 폰트.
    ///
    /// 폰트 파일은 앱 번들이 아니라 DesignSystem 리소스 번들에 있다.
    /// Tuist가 합성한 `DesignSystemFontFamily`가 처음 쓸 때 등록하므로 Info.plist의 `UIAppFonts`는 필요 없다.
    public enum ComingSoon {
        public static let largeTitle = font(size: 48)
        public static let title = font(size: 25)
        public static let title2 = font(size: 24)

        private static func font(size: CGFloat) -> Font {
            DesignSystemFontFamily.ComingSoon.regular.swiftUIFont(size: size)
        }
    }
}
