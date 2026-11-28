import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct SettingView: View {
    @Bindable var store: StoreOf<SettingFeature>

    public init(store: StoreOf<SettingFeature>) {
        self.store = store
    }

    public var body: some View {
        // 작은 기기나 큰 글씨에서는 한 화면에 다 들어가지 않는다.
        ScrollView {
            VStack(spacing: 20) {
                accountSection
                    .padding(.bottom, 40)

                deviceSection

                divider

                aboutUsSection
                    .padding(.bottom, 16)

                if store.email != nil {
                    accountActions
                        .padding(.top, 32)
                        .padding(.bottom, 10)
                }

                versionLabel
                    .padding(.top, 24)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystemAsset.Colors.bgPrimary.swiftUIColor.ignoresSafeArea())
        .task { await store.send(.view(.task)).finish() }
        .toast(message: toastBinding)
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .sheet(isPresented: webPageBinding) {
            if let url = store.destination?.webPage {
                WebPageView(url: url)
                    .ignoresSafeArea(edges: .bottom)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large])
            }
        }
        .sheet(item: $store.scope(state: \.destination?.feedback, action: \.destination.feedback)) { feedbackStore in
            FeedbackView(store: feedbackStore)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }

    // MARK: - 섹션

    private var accountSection: some View {
        AppleLoginView(email: store.email, isLoading: store.isSigningIn) {
            store.send(.view(.appleSignInCompleted($0)))
        }
    }

    private var deviceSection: some View {
        VStack(spacing: 16) {
            ForEach(SettingMenuType.DeviceSetting.allCases, id: \.self) { item in
                SettingMenu(type: .device(item)) {
                    CommonToggle(isOn: binding(item))
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(DesignSystemAsset.Colors.systemLightGray.swiftUIColor)
            .frame(height: 1)
    }

    private var aboutUsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Us")
                .font(.caption)
                .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)

            ForEach(SettingMenuType.AboutUs.allCases, id: \.self) { item in
                Button {
                    store.send(.view(.aboutUsTapped(item)))
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
    }

    /// Apple 계정으로 로그인했을 때만 보인다.
    private var accountActions: some View {
        HStack(spacing: 30) {
            Button {
                store.send(.view(.logoutTapped))
            } label: {
                Text("Sign Out")
                    .font(.caption)
                    .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
            }

            Button {
                store.send(.view(.withdrawalTapped))
            } label: {
                Text("Delete Account")
                    .font(.caption)
                    .foregroundStyle(DesignSystemAsset.Colors.systemRed.swiftUIColor)
            }
        }
    }

    private var versionLabel: some View {
        Text(AppVersion.display())
            .font(.caption2)
            .foregroundStyle(DesignSystemAsset.Colors.labelVibrantTertiary.swiftUIColor)
            .accessibilityLabel("Version \(AppVersion.display())")
    }

    // MARK: - 바인딩

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

    /// 토스트가 시간이 지나 사라지면 nil이 들어온다.
    private var toastBinding: Binding<String?> {
        Binding(
            get: { store.toast },
            set: { if $0 == nil { store.send(.view(.toastDismissed)) } }
        )
    }

    /// 읽기는 store 값, 쓰기는 `deviceSettingChanged` 액션으로 보내는 바인딩.
    private func binding(_ type: SettingMenuType.DeviceSetting) -> Binding<Bool> {
        Binding(
            get: { store.setting[type] },
            set: { store.send(.view(.deviceSettingChanged(type: type, isOn: $0))) }
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
