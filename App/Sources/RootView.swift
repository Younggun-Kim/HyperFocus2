import ComposableArchitecture
import FocusTimer
import SessionLog
import Setting
import SwiftUI

struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>

    var body: some View {
        TabView {
            Tab("타이머", systemImage: "timer") {
                FocusHomeView(store: store.scope(state: \.timer, action: \.timer))
            }
            Tab("기록", systemImage: "list.bullet") {
                NavigationStack(path: $store.scope(state: \.logPath, action: \.logPath)) {
                    SessionLogHomeView(store: store.scope(state: \.log, action: \.log))
                } destination: { store in
                    switch store.case {
                    case let .setting(store):
                        SettingView(store: store)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView(
        store: Store(initialState: RootFeature.State()) {
            RootFeature()
        }
    )
}
