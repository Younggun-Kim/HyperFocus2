import ComposableArchitecture
import FocusTimer
import SessionHistory


@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        var timer = FocusHomeFeature.State()
        var log = SessionLogHomeFeature.State()
    }
    
    enum Action: Equatable {
        case timer(FocusHomeFeature.Action)
        case log(SessionLogHomeFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.timer, action: \.timer) { FocusHomeFeature() }
        Scope(state: \.log, action: \.log) { SessionLogHomeFeature() }
        
        Reduce { _, action in
            switch action {
            case .timer, .log:
                return .none
            }
        }
    }
}
