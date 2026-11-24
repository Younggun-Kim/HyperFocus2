import ComposableArchitecture
import SwiftUI

public struct SettingView: View {
    let store: StoreOf<SettingFeature>

    public init(store: StoreOf<SettingFeature>) {
        self.store = store
    }

    public var body: some View {
        Text("Setting")
            .onAppear { store.send(.onAppear) }
    }
}

#Preview {
    SettingView(
        store: Store(initialState: SettingFeature.State()) {
            SettingFeature()
        }
    )
}
