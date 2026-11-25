//
//  SettingRow.swift
//  Setting
//
//  Created by 김영건 on 11/24/26.
//

import DesignSystem
import Foundation
import SwiftUI

enum SettingRowType {
    case privacyPolicy
    case termsOfService
    case talkToDeveloper
}

extension SettingRowType {
    var icon: Image {
        switch self {
        case .privacyPolicy: return Image(systemName: "figure.2")
        case .termsOfService: return Image(systemName: "book.circle")
        case .talkToDeveloper: return Image(systemName: "paperplane.fill")
        }
    }

    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        case .talkToDeveloper: return "Talk to Developer"
        }
    }
}

struct SettingRow: View {
    let type: SettingRowType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                type.icon
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Color(red: 118 / 255, green: 118 / 255, blue: 128 / 255, opacity: 0.3),
                        in: .rect(cornerRadius: 8)
                    )
                    .accessibilityHidden(true)

                Text(type.title)
                    .font(.body.bold())
                    .tracking(-0.08)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .frame(width: 13, height: 10)
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingRow(type: .privacyPolicy) {}
        SettingRow(type: .termsOfService) {}
        SettingRow(type: .talkToDeveloper) {}
    }
    .padding()
    .background(Color.black)
}
