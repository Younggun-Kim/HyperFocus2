import ComposableArchitecture
import SwiftUI
import Utils

public struct FocusTimerView: View {
    let store: StoreOf<FocusTimerFeature>

    public init(store: StoreOf<FocusTimerFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text(TimeFormatter.minuteSecond(from: store.remainingSeconds))
                .font(.system(size: 64, weight: .semibold, design: .monospaced))

            HStack(spacing: 16) {
                if store.isRunning {
                    Button("일시정지") { store.send(.pauseTapped) }
                } else {
                    Button("시작") { store.send(.startTapped) }
                }
                Button("초기화") { store.send(.resetTapped) }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    FocusTimerView(
        store: Store(initialState: FocusTimerFeature.State(duration: 5)) {
            FocusTimerFeature()
        }
    )
}
