//
//  FeedbackFeature.swift
//  Setting
//

import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct FeedbackFeature {
    @ObservableState
    public struct State: Equatable {
        static let maxLength = 500

        var category: FeedbackCategory
        var text: String
        var isSending: Bool
        @Presents var alert: AlertState<Action.Alert>?

        var canSend: Bool {
            !isSending && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init(
            category: FeedbackCategory = .featureIdea,
            text: String = "",
            isSending: Bool = false
        ) {
            self.category = category
            self.text = text
            self.isSending = isSending
        }
    }

    public enum Action: Equatable {
        case categoryTapped(FeedbackCategory)
        case textChanged(String)
        case closeTapped
        case sendTapped
        case sendSucceeded
        case sendFailed(DomainError)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {}

        public enum Delegate: Equatable {
            /// 전송 성공. 시트를 닫는 것은 부모가 한다.
            case sent
        }
    }

    @Dependency(\.sendFeedbackUseCase) var sendFeedbackUseCase
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .categoryTapped(category):
                state.category = category
                return .none

            case let .textChanged(text):
                state.text = String(text.prefix(State.maxLength))
                return .none

            case .closeTapped:
                return .run { _ in await dismiss() }

            case .sendTapped:
                guard state.canSend else { return .none }
                state.isSending = true
                return .run { [category = state.category, content = state.text] send in
                    // 시트가 닫혀 취소되면 `send`가 액션을 버린다. 알릴 대상이 없다.
                    switch await sendFeedbackUseCase.execute(category, content) {
                    case .success: await send(.sendSucceeded)
                    case .failure(let error): await send(.sendFailed(error))
                    }
                }

            case .sendSucceeded:
                state.isSending = false
                return .send(.delegate(.sent))

            case let .sendFailed(error):
                state.isSending = false
                state.alert = .sendFailure(error)
                return .none

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == FeedbackFeature.Action.Alert {
    /// 전송 실패 알림. 입력한 내용은 그대로 두므로 다시 보내면 된다.
    static func sendFailure(_ error: DomainError) -> Self? {
        .failure(title: "Failed to send feedback.", error: error)
    }
}
