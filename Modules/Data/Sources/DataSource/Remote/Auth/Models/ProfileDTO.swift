//
//  ProfileDTO.swift
//  Data
//
//  Created by 김영건 on 11/27/26.
//

import Foundation


struct ProfileResponseDTO: Decodable, Sendable, Equatable {
    public let userId: String
    public let email: String
    public let name: String
    public let profileImageUrl: String?
    public let provider: String
    public let role: String
    public let status: String
    public let lastLoginAt: Date
    public let createdAt: Date
    public let profileImageUrlOptional: String?
}
