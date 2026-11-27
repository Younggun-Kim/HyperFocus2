//
//  AuthRepository+Mapper.swift
//  Data
//
//  Created by 김영건 on 11/27/26.
//

import Foundation
import Domain
import os


extension ProfileResponseDTO {
    /// 모르는 provider면 실패한다. 익명으로 넘기면 연동된 계정이 비로그인으로 보인다.
    func toEntity() -> Result<Profile, DomainError> {
        guard let provider = AccountProvider(serverKey: provider) else {
            Logger.data.error("프로필 변환 실패: 모르는 provider \(provider)")
            return .failure(.unknown)
        }

        return .success(
            Profile(
                userId: userId,
                email: email,
                name: name,
                profileImageUrl: profileImageUrl,
                provider: provider,
                role: role,
                status: status,
                lastLoginAt: lastLoginAt,
                createdAt: createdAt,
                profileImageUrlOptional: profileImageUrlOptional
            )
        )
    }
}

extension AccountProvider {
    fileprivate init?(serverKey: String) {
        switch serverKey {
        case "APPLE": self = .apple
        case "ANONYMOUS": self = .anonymous
        default: return nil
        }
    }
}
