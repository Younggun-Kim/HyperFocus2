import ComposableArchitecture
import Domain
import SwiftUI

public struct SessionHistoryView: View {
    let store: StoreOf<SessionHistoryFeature>

    public init(store: StoreOf<SessionHistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            if let errorMessage = store.errorMessage {
                Text("불러오기 실패: \(errorMessage)")
                    .foregroundStyle(.red)
            }
            if store.samples.isEmpty {
                Text("기록이 없습니다")
                    .foregroundStyle(.secondary)
            }
            ForEach(store.samples) { sample in
                Text(sample.id)
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}

#Preview {
    SessionHistoryView(
        store: Store(initialState: SessionHistoryFeature.State()) {
            SessionHistoryFeature()
        }
    )
}
