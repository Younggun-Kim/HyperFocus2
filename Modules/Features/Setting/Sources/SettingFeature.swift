import ComposableArchitecture
import Foundation

@Reducer
public struct SettingFeature {
    /// 설정 화면에서 띄우는 시트.
    @Reducer
    public enum Destination {
        /// 개인정보처리방침, 이용약관. 로직이 없어 주소만 들고 있다.
        @ReducerCaseIgnored
        case webPage(URL)
        case feedback(FeedbackFeature)
    }

    @ObservableState
    public struct State: Equatable {
        var soundOn: Bool
        var hapticOn: Bool
        var alarmOn: Bool
        @Presents var destination: Destination.State?

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
        case deviceSettingChanged(type: SettingMenuType.DeviceSetting, isOn: Bool)
        case aboutUsTapped(SettingMenuType.AboutUs)
        case destination(PresentationAction<Destination.Action>)
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
            case let .aboutUsTapped(item):
                if let url = item.url {
                    state.destination = .webPage(url)
                } else {
                    state.destination = .feedback(FeedbackFeature.State())
                }
                return .none
            case .destination(.presented(.feedback(.delegate(.sent)))):
                state.destination = nil
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension SettingFeature.Destination.State: Equatable {}
extension SettingFeature.Destination.Action: Equatable {}
