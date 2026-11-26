import ComposableArchitecture
import Foundation

@Reducer
public struct SplashFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Phase: Equatable, Sendable {
            /// 빛 이미지를 보여 준다.
            case light
            /// 빛 이미지가 흐려진다.
            case blurring
            /// 앱 이름을 보여 준다.
            case title
        }
        
        public internal(set) var phase: Phase = .light
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case phaseChanged(State.Phase)
        case delegate(Delegate)
        
        @CasePathable
        public enum Delegate: Equatable {
            /// 연출이 끝났다.
            case finished
        }
    }
    
    /// 한 단계가 머무는 시간
    static let phaseDuration: Duration = .seconds(1)
    
    private enum CancelID { case timeline }
    
    @Dependency(\.continuousClock) var clock
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.phase = .light
                // 화면이 사라져 취소되면 sleep이 던지고, 뒤의 액션은 나가지 않는다.
                return .run { send in
                    try await clock.sleep(for: Self.phaseDuration)
                    await send(.phaseChanged(.blurring))
                    try await clock.sleep(for: Self.phaseDuration)
                    await send(.phaseChanged(.title))
                    try await clock.sleep(for: Self.phaseDuration)
                    await send(.delegate(.finished))
                }
                .cancellable(id: CancelID.timeline, cancelInFlight: true)
                
            case let .phaseChanged(phase):
                state.phase = phase
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
