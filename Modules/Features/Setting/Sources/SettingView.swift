import ComposableArchitecture
import SwiftUI

public struct SettingView: View {
    let store: StoreOf<SettingFeature>
    
    public init(store: StoreOf<SettingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            VStack(spacing: 16) {
                DeviceSettingItem(type: .sound, isOn: binding(.sound, store.soundOn))
                DeviceSettingItem(type: .haptic, isOn: binding(.haptic, store.hapticOn))
                DeviceSettingItem(type: .alarm, isOn: binding(.alarm, store.alarmOn))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
    
    /// 읽기는 store 값, 쓰기는 `deviceSettingChanged` 액션으로 보내는 바인딩.
    private func binding(_ type: DeviceSettingItemType, _ value: Bool) -> Binding<Bool> {
        Binding(
            get: { value },
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
