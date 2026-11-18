import ComposableArchitecture
import FocusTimer
import SessionHistory
import SwiftUI

struct ContentView: View {
    let store: StoreOf<RootFeature>

    var body: some View {
        TabView {
            Tab("타이머", systemImage: "timer") {
                FocusTimerView(store: store.scope(state: \.timer, action: \.timer))
            }
            Tab("기록", systemImage: "list.bullet") {
                SessionHistoryView(store: store.scope(state: \.history, action: \.history))
            }
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: RootFeature.State()) {
            RootFeature()
        }
    )
}
