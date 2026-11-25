//
//  FeedbackView.swift
//  Setting
//

import ComposableArchitecture
import DesignSystem
import Domain
import SwiftUI

struct FeedbackView: View {
    @Bindable var store: StoreOf<FeedbackFeature>

    var body: some View {
        // 키보드가 올라와도 입력 칸이 눌리지 않도록 내용은 스크롤하고, 전송 버튼은 아래에 고정한다.
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, 20)
                    .padding(.bottom, 40)

                Text("Categories")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.title,
                            isSelected: store.category == category
                        ) {
                            store.send(.categoryTapped(category))
                        }
                    }
                }
                .padding(.bottom, 50)

                input
                    .frame(height: 280)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            sendButton
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.11).ignoresSafeArea())
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    private var sendButton: some View {
        Button {
            store.send(.sendTapped)
        } label: {
            Group {
                if store.isSending {
                    ProgressView().tint(.white)
                } else {
                    Text("Send").font(.body.bold())
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(DesignSystemAsset.Colors.systemBlue.swiftUIColor, in: .capsule)
        }
        .disabled(!store.canSend)
        .opacity(store.canSend || store.isSending ? 1 : 0.4)
    }

    private var header: some View {
        ZStack {
            Text("Talk To Developer")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Button {
                    store.send(.closeTapped)
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.3), in: .circle)
                }
                .accessibilityLabel("Close")
                Spacer()
            }
        }
    }

    private var input: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $store.text.sending(\.textChanged))
                .autocorrectionDisabled()
                .scrollContentBackground(.hidden)
                .font(.title)
                .foregroundStyle(DesignSystemAsset.Colors.systemBlue.swiftUIColor)
                .padding(20)

            if store.text.isEmpty {
                Text(store.category.hint)
                    .font(.title)
                    .foregroundStyle(.gray)
                    .padding(26)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Text("\(store.text.count) / \(FeedbackFeature.State.maxLength)")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(20)
                .allowsHitTesting(false)
        }
        .background(
            DesignSystemAsset.Colors.systemLightGray.swiftUIColor,
            in: .rect(cornerRadius: 16)
        )
    }
}

/// 카테고리 선택 칩. DesignSystem에 공통 칩이 생기면 그쪽으로 옮긴다.
private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected ? Color.white : DesignSystemAsset.Colors.systemLightGray.swiftUIColor,
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    FeedbackView(
        store: Store(initialState: FeedbackFeature.State()) {
            FeedbackFeature()
        }
    )
}
