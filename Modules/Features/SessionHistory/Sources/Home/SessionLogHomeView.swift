//
//  SessionLogHomeView.swift
//  SessionHistory
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
    }
}

#Preview {
    SessionLogHomeView(
        store: Store(initialState: SessionLogHomeFeature.State()) {
            SessionLogHomeFeature()
        }
    )
}
