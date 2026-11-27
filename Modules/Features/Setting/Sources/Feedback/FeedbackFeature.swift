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
        @Presents var alert: AlertState<Never>?

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

    public enum Action {
        case view(ViewAction)
        case effect(EffectAction)
        case alert(PresentationAction<Never>)
        case delegate(Delegate)

        /// 사용자가 화면에서 한 일.
        @CasePathable
        public enum ViewAction {
            case categoryTapped(FeedbackCategory)
            case textChanged(String)
            case closeTapped
            case sendTapped
        }

        /// UseCase 응답.
        @CasePathable
        public enum EffectAction {
            case sendResponse(Result<Void, DomainError>)
        }

        @CasePathable
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
            case .view(let action):
                return viewAction(&state, action)

            case .effect(let action):
                return effectAction(&state, action)

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - View

    private func viewAction(_ state: inout State, _ action: Action.ViewAction) -> Effect<Action> {
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
            return sendFeedback(category: state.category, content: state.text)
        }
    }

    // MARK: - Effect

    private func effectAction(_ state: inout State, _ action: Action.EffectAction) -> Effect<Action> {
        switch action {
        case let .sendResponse(result):
            state.isSending = false
            switch result {
            case .success:
                return .send(.delegate(.sent))
            case let .failure(error):
                state.alert = .feedbackSendFailure(error)
                return .none
            }
        }
    }

    /// 시트가 닫혀 취소되면 `send`가 액션을 버린다. 알릴 대상이 없다.
    private func sendFeedback(category: FeedbackCategory, content: String) -> Effect<Action> {
        .run { send in
            await send(.effect(.sendResponse(sendFeedbackUseCase.execute(category, content))))
        }
    }
}
