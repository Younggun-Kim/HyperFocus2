import ComposableArchitecture
import FocusTimer
import SessionLog
import Setting
import Splash
import SwiftUI

struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // 메인은 스플래시가 끝난 뒤에 만든다. 미리 만들면 자식 화면의 요청이 로그인 확인보다 먼저 나간다.
            if store.isLaunching {
                SplashView(store: store.scope(state: \.splash, action: \.splash))
                    .transition(.opacity)
            } else {
                main
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.isLaunching)
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            store.send(.view(.onAppear))
        }
        .task {
            await store.send(.view(.task)).finish()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.send(.view(.sceneActivated))
            }
        }
    }

    private var main: some View {
        TabView(selection: $store.selectedTab.sending(\.view.tabSelected)) {
            Tab("타이머", systemImage: "timer", value: RootFeature.Tab.timer) {
                FocusHomeView(store: store.scope(state: \.timer, action: \.timer))
            }
            Tab("기록", systemImage: "list.bullet", value: RootFeature.Tab.log) {
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
