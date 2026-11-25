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
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystemAsset.Colors.bgPrimary.swiftUIColor.ignoresSafeArea())
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
            get: {
                switch type {
                case .sound: store.soundOn
                case .haptic: store.hapticOn
                case .alarm: store.alarmOn
                }
            },
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
