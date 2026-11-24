import ComposableArchitecture
import Foundation

@Reducer
public struct SettingFeature {
    @ObservableState
    public struct State: Equatable {
        var soundOn: Bool
        var hapticOn: Bool
        var alarmOn: Bool
        
        public init(
            soundOn: Bool = false,
            hapticOn: Bool = false,
            alarmOn: Bool = false,
        ) {
            self.soundOn = soundOn
            self.hapticOn = hapticOn
            self.alarmOn = alarmOn
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case deviceSettingChanged(type: DeviceSettingItemType, isOn: Bool)
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case let .deviceSettingChanged(type, isOn):
                switch type {
                case .sound: state.soundOn = isOn
                case .haptic: state.hapticOn = isOn
                case .alarm: state.alarmOn = isOn
                }
                return .none
            }
        }
    }
}
