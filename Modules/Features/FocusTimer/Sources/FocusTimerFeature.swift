import ComposableArchitecture
import Foundation

@Reducer
public struct FocusTimerFeature {
    @ObservableState
    public struct State: Equatable {
        public var duration: Int
        public var remainingSeconds: Int
        public var isRunning = false

        public init(duration: Int = 25 * 60) {
            self.duration = duration
            self.remainingSeconds = duration
        }
    }

    public enum Action: Equatable {
        case startTapped
        case pauseTapped
        case resetTapped
        case tick
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            /// 집중 시간을 끝까지 채웠을 때 부모에게 알린다.
            case sessionFinished(seconds: Int)
        }
    }

    private enum CancelID { case timer }

    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startTapped:
                guard !state.isRunning, state.remainingSeconds > 0 else { return .none }
                state.isRunning = true
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)

            case .pauseTapped:
                state.isRunning = false
                return .cancel(id: CancelID.timer)

            case .resetTapped:
                state.isRunning = false
                state.remainingSeconds = state.duration
                return .cancel(id: CancelID.timer)

            case .tick:
                state.remainingSeconds -= 1
                guard state.remainingSeconds <= 0 else { return .none }
                state.remainingSeconds = 0
                state.isRunning = false
                return .merge(
                    .cancel(id: CancelID.timer),
                    .send(.delegate(.sessionFinished(seconds: state.duration)))
                )

            case .delegate:
                return .none
            }
        }
    }
}
