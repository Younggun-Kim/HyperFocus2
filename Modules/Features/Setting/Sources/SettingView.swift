import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct SettingView: View {
    let store: StoreOf<SettingFeature>

    public init(store: StoreOf<SettingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ForEach(SettingMenuType.DeviceSetting.allCases, id: \.self) { item in
                    SettingRow(type: .device(item)) {
                        CommonToggle(isOn: binding(item))
                    }
                }
            }

            VStack(spacing: 16) {
                ForEach(SettingMenuType.AboutUs.allCases, id: \.self) { item in
                    Button {
                        store.send(.aboutUsTapped(item))
                    } label: {
                        SettingRow(type: .aboutUs(item)) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.white)
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
        .background(Color.black.ignoresSafeArea())
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
