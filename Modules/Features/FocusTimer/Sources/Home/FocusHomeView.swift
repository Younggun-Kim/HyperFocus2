//
//  FocusHomeView.swift
//  FocusTimer
//
//  Created by 김영건 on 11/24/26.
//

import ComposableArchitecture
import DesignSystem
import SwiftUI
import Util

public struct FocusHomeView: View {
    let store: StoreOf<FocusHomeFeature>

    public init(store: StoreOf<FocusHomeFeature>) {
        self.store = store
    }

    public var body: some View {
        AmbientZStack(style: .input){
            Text("Focus")
                .foregroundStyle(
                    DesignSystemAsset.Colors.labelPrimary.swiftUIColor
                )
        }
    }
}

#Preview {
    FocusHomeView(
        store: Store(initialState: FocusHomeFeature.State()) {
            FocusHomeFeature()
        }
    )
}

