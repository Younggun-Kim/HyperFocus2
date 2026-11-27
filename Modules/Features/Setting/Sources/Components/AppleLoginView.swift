import AuthenticationServices
import DesignSystem
import SwiftUI

/// 설정 화면 맨 위의 계정 카드. 로그인 전에는 Apple 로그인 버튼을, 로그인 후에는 email을 보여 준다.
struct AppleLoginView: View {
    var email: String?
    var onCompletion: (AppleSignInResult) -> Void = { _ in }

    var body: some View {
        if let email {
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
        AppleLoginView(email: "test@example.com")
    }
    .preferredColorScheme(.light)
}

#Preview("Theme - Dark") {
    VStack {
        AppleLoginView()
        AppleLoginView(email: "test@example.com")
    }
    .preferredColorScheme(.dark)
}
