//
//  FocusHomeView.swift
//  FocusTimer
//
//  Created by 김영건 on 11/24/26.
//

import ComposableArchitecture
import SwiftUI
import Util

public struct FocusHomeView: View {
    let store: StoreOf<FocusHomeFeature>
    
    public init(store: StoreOf<FocusHomeFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Text("포커스 홈")
        }
        .padding()
    }
}

#Preview {
    FocusHomeView(
        store: Store(initialState: FocusHomeFeature.State()) {
            FocusHomeFeature()
        }
    )
}

