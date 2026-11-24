//
//  SessionLogHomeView.swift
//  SessionLog
//
//  Created by 김영건 on 11/24/26.
//


import ComposableArchitecture
import Domain
import SwiftUI
import DesignSystem

public struct SessionLogHomeView: View {
    let store: StoreOf<SessionLogHomeFeature>
    
    public init(store: StoreOf<SessionLogHomeFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            Text("세션 로그 홈")
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .toolbar {
            if #available(iOS 26.0, *) {
                settingToolbarItem
                    .sharedBackgroundVisibility(.hidden)
            } else {
                settingToolbarItem
            }
        }
    }

    private var settingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.send(.settingButtonTapped)
            } label: {
                DesignSystemAsset.icGear.swiftUIImage
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Setting")
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
