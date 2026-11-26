import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct SplashView: View {
    let store: StoreOf<SplashFeature>

    public init(store: StoreOf<SplashFeature>) {
        self.store = store
    }

    private var isTitle: Bool {
        store.phase == .title
    }

    public var body: some View {
        AmbientZStack(style: isTitle ? .black : .all121619) {
            DesignSystemAsset.Assets.splashLight.swiftUIImage
                .offset(x: 100, y: -160)
                .overlay(alignment: .topTrailing) {
                    DesignSystemAsset.Assets.splashCircle.swiftUIImage
                        .frame(width: 40, height: 40)
                        .alignmentGuide(.top) { $0[.bottom] - 220 }
                        .alignmentGuide(.trailing) { $0[.leading] + 100 }
                }
                .blur(radius: store.phase == .light ? 0 : 50)
                .opacity(isTitle ? 0 : 1)

            if isTitle {
                Text("HyperFocus")
                    .font(.ComingSoon.largeTitle)
                    .foregroundStyle(.white)
                    .transition(.opacity)
            }
        }
        // 흐려지는 것은 단계 시간(1초)을 다 쓰고, 타이틀은 절반 동안 나타나 나머지 절반은 머문다.
        .animation(.easeInOut(duration: isTitle ? 0.5 : 1), value: store.phase)
        .onAppear { store.send(.onAppear) }
    }
}

#Preview {
    SplashView(
        store: Store(initialState: SplashFeature.State()) {
            SplashFeature()
        }
    )
}
