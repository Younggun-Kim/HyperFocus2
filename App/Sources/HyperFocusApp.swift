import ComposableArchitecture
import Data
import SwiftUI

@main
struct HyperFocusApp: App {
    init() {
        // Store가 의존성에 처음 접근하기 전에 Data의 live 구현을 등록한다.
        DataModule.bootstrap()
    }

    @MainActor static let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: Self.store)
        }
    }
}
