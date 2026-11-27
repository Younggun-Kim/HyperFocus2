import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct SettingView: View {
    @Bindable var store: StoreOf<SettingFeature>
    
    public init(store: StoreOf<SettingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            AppleLoginView(email: store.email) { store.send(.appleSignInCompleted($0)) }
                .padding(.bottom, 40)
            
            VStack(spacing: 16) {
                ForEach(SettingMenuType.DeviceSetting.allCases, id: \.self) { item in
                    SettingMenu(type: .device(item)) {
                        CommonToggle(isOn: binding(item))
                    }
                }
            }
            
            Rectangle()
                .fill(DesignSystemAsset.Colors.systemLightGray.swiftUIColor)
                .frame(height: 1)
            
            VStack(alignment: .leading,spacing: 16) {
                Text("About Us")
                    .font(.caption)
                    .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                
                ForEach(SettingMenuType.AboutUs.allCases, id: \.self) { item in
                    Button {
                        store.send(.aboutUsTapped(item))
                    } label: {
                        SettingMenu(type: .aboutUs(item)) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 16)
            
            if store.email != nil {
                HStack(spacing: 30) {
                    Button(action: {
                    
                    }) {
                        Text("Sign Out")
                            .font(.caption)
                            .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                    }
                    Button(action: {
                    
                    }) {
                        Text("Delete Account")
                            .font(.caption)
                            .foregroundStyle(DesignSystemAsset.Colors.systemRed.swiftUIColor)
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 10)
            
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystemAsset.Colors.bgPrimary.swiftUIColor.ignoresSafeArea())
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .sheet(isPresented: webPageBinding) {
            if let url = store.destination?.webPage {
                WebPageView(url: url)
                    .ignoresSafeArea(edges: .bottom)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large])
            }
        }
        .sheet(item: $store.scope(
            state: \.destination?.feedback,
            action: \.destination.feedback)
        ) { feedbackStore in
            FeedbackView(store: feedbackStore)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
    
    /// 웹 페이지 케이스는 리듀서가 없어 scope로 바인딩할 수 없으므로 직접 만든다.
    private var webPageBinding: Binding<Bool> {
        Binding(
            get: { store.destination?.webPage != nil },
            set: { isPresented in
                if !isPresented, store.destination?.webPage != nil {
                    store.send(.destination(.dismiss))
                }
            }
        )
    }
    
    /// 읽기는 store 값, 쓰기는 `deviceSettingChanged` 액션으로 보내는 바인딩.
    private func binding(_ type: SettingMenuType.DeviceSetting) -> Binding<Bool> {
        Binding(
            get: { store.setting[type] },
            set: { store.send(.deviceSettingChanged(type: type, isOn: $0)) }
        )
    }
}

#Preview {
    SettingView(
        store: Store(initialState: SettingFeature.State()) {
            SettingFeature()
        }
    )
}
