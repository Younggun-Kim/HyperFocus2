//
//  Profile.swift
//  HyperFocus
//
//  Created by 김영건 on 11/27/26.
//

import Foundation

public struct Profile: Sendable, Equatable {
    public let userId: String
    public let email: String
    public let name: String
    public let profileImageUrl: String?
    public let provider: AccountProvider
    public let role: String
    public let status: String
    public let lastLoginAt: Date
    public let createdAt: Date
    public let profileImageUrlOptional: String?

    public init(
        userId: String,
        email: String,
        name: String,
        profileImageUrl: String?,
        provider: AccountProvider,
        role: String,
        status: String,
        lastLoginAt: Date,
        createdAt: Date,
        profileImageUrlOptional: String?) {
            self.userId = userId
            self.email = email
            self.name = name
            self.profileImageUrl = profileImageUrl
            self.provider = provider
            self.role = role
            self.status = status
            self.lastLoginAt = lastLoginAt
            self.createdAt = createdAt
            self.profileImageUrlOptional = profileImageUrlOptional
        }
}

extension Profile {

    public var isAppleUser: Bool {
        provider == .apple
    }

    public static let mock = Self(
        userId: "550e8400-e29b-41d4-a716-446655440000",
        email: "user@example.com",
        name: "홍길동",
        profileImageUrl: "https://example.com/profile.jpg",
        provider: .apple,
        role: "USER",
        status: "ACTIVE",
        lastLoginAt: Date(timeIntervalSince1970: 1234567890),
        createdAt: Date(timeIntervalSince1970: 1234567890),
        profileImageUrlOptional: nil
    )
}
