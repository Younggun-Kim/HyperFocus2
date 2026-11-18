import ComposableArchitecture
import SwiftUI

@main
struct HyperFocusApp: App {
    @MainActor static let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: Self.store)
        }
    }
}
