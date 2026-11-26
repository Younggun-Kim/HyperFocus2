//
//  AppleLoginView.swift
//  Setting
//
//  Created by 김영건 on 11/25/26.
//

import Foundation
import SwiftUI
import DesignSystem
import AuthenticationServices


struct AppleLoginView: View {
    
    var email: String?
    var onCompletion: (AppleSignInResult) -> Void = { _ in }

    var body: some View {
        if email == nil {
            anonymousUser
        } else {
            appleUser
        }
    }
    
    var anonymousUser: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 5,
                ) {
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
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(DesignSystemAsset.Colors.systemLightGray.swiftUIColor)
        }
    }
    
    var appleUser: some View {
        
        VStack(alignment: .leading) {
            Text("Email")
                .font(.caption)
                .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
            Text(email ?? "")
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
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(
            .init(top: 20, leading: 16, bottom: 25, trailing: 16)
        )
        .background {
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
