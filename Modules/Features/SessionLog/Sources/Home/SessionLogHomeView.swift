//
//  SessionLogHomeView.swift
//  SessionLog
//
//  Created by 김영건 on 11/24/26.
//


import ComposableArchitecture
import Domain
import SwiftUI

public struct SessionLogHomeView: View {
    let store: StoreOf<SessionLogHomeFeature>
    
    public init(store: StoreOf<SessionLogHomeFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            Text("세션 로그 홈")
        }
        .padding()
        .navigationTitle("기록")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.settingButtonTapped)
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("설정")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SessionLogHomeView(
            store: Store(initialState: SessionLogHomeFeature.State()) {
                SessionLogHomeFeature()
            }
        )
    }
}
