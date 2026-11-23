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

    /// 선제 갱신은 하지 않는다. 갱신은 401을 받았을 때만 한다.
    public var requiresRefresh: Bool { false }

    var authorizationHeader: String { "\(tokenType) \(accessToken)" }
}
