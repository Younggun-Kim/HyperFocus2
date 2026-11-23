//
//  AuthToken.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/23/26.
//

import Alamofire

public struct AuthToken: AuthenticationCredential, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String

    public init(accessToken: String, refreshToken: String, tokenType: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
    }

    // TODO: 7단계 선제 갱신
    public var requiresRefresh: Bool { false }

    var authorizationHeader: String { "\(tokenType) \(accessToken)" }
}
