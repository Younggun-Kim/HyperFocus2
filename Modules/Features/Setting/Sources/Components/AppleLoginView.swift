import AuthenticationServices
import DesignSystem
import SwiftUI

/// 설정 화면 맨 위의 계정 카드. 로그인 전에는 Apple 로그인 버튼을, 로그인 후에는 email을 보여 준다.
/// 로그인 요청부터 새 프로필을 받을 때까지는 로딩을 보여 준다.
struct AppleLoginView: View {
    var email: String?
    var isLoading = false
    var onCompletion: (AppleSignInResult) -> Void = { _ in }

    var body: some View {
        if isLoading {
            loadingCard
        } else if let email {
            signedInCard(email: email)
        } else {
            signInPrompt
        }
    }

    private var signInPrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Don't lose your journey")
                        .font(.body.bold())
                        .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                    Text("Your focus history is stored locally.\nBack it up now")
                        .font(.caption)
                        .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                }
                .padding(.horizontal, 10)
                Spacer()
                Text("🚀")
                    .font(.largeTitle.bold())
            }
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    onCompletion(AppleSignInResult(result))
                }
            )
            .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 20, leading: 16, bottom: 24, trailing: 16))
        .settingCard()
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
            Text("Signing in…")
                .font(.caption)
                .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
        }
        // 로그인 카드와 높이를 비슷하게 맞춰 바뀔 때 아래 메뉴가 덜 움직이게 한다.
        .frame(maxWidth: .infinity, minHeight: 150)
        .settingCard()
        .accessibilityElement(children: .combine)
    }

    private func signedInCard(email: String) -> some View {
        VStack(alignment: .leading) {
            Text("Email")
                .font(.caption)
                .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
            Text(email)
                .font(.title.bold())
                .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                .padding(.bottom, 35)
            Text("☁️ Saved")
                .font(.caption)
                .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(DesignSystemAsset.Colors.bgPrimary.swiftUIColor)
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 20, leading: 16, bottom: 25, trailing: 16))
        .settingCard()
    }
}

private extension View {
    /// 계정 카드의 둥근 회색 배경.
    func settingCard() -> some View {
        background {
            RoundedRectangle(cornerRadius: 24)
                .fill(DesignSystemAsset.Colors.systemLightGray.swiftUIColor)
        }
    }
}

#Preview("Theme - Light") {
    VStack {
        AppleLoginView()
        AppleLoginView(isLoading: true)
        AppleLoginView(email: "test@example.com")
    }
    .preferredColorScheme(.light)
}

#Preview("Theme - Dark") {
    VStack {
        AppleLoginView()
        AppleLoginView(isLoading: true)
        AppleLoginView(email: "test@example.com")
    }
    .preferredColorScheme(.dark)
}
