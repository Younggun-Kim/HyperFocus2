import ComposableArchitecture
import Data

@Reducer
public struct SessionHistoryFeature {
    @ObservableState
    public struct State: Equatable {
        public var samples: [Sample] = []
        public var errorMessage: String?

        public init(samples: [Sample] = []) {
            self.samples = samples
        }
    }

    public enum Action: Equatable {
        case onAppear
        case reload
        case samplesResponse(Result<[Sample], LoadError>)
    }

    public struct LoadError: Error, Equatable {
        public let message: String
    }

    @Dependency(\.sampleClient) var sampleClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .reload:
                return .run { send in
                    do {
                        let samples = try await sampleClient.getSamples()
                        await send(.samplesResponse(.success(samples)))
                    } catch {
                        await send(.samplesResponse(.failure(LoadError(message: "\(error)"))))
                    }
                }

            case let .samplesResponse(.success(samples)):
                state.samples = samples
                state.errorMessage = nil
                return .none

            case let .samplesResponse(.failure(error)):
                state.errorMessage = error.message
                return .none
            }
        }
    }
}
