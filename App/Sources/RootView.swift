import ComposableArchitecture
import FocusTimer
import SessionHistory
import SwiftUI

struct RootView: View {
    let store: StoreOf<RootFeature>

    var body: some View {
        TabView {
            Tab("타이머", systemImage: "timer") {
                FocusHomeView(store: store.scope(state: \.timer, action: \.timer))
            }
            Tab("기록", systemImage: "list.bullet") {
                SessionLogHomeView(store: store.scope(state: \.log, action: \.log))
            }
        }
    }
}

#Preview {
    RootView(
        store: Store(initialState: RootFeature.State()) {
            RootFeature()
        }
    )
}
