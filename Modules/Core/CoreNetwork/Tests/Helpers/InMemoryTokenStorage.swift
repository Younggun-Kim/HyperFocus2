//
//  InMemoryTokenStorage.swift
//  CoreNetworkTests
//
//  Created by 김영건 on 11/23/26.
//

import Synchronization
@testable import CoreNetwork

final class InMemoryTokenStorage: TokenStorage {
    private let token: Mutex<AuthToken?>

    init(_ token: AuthToken? = nil) {
        self.token = Mutex(token)
    }

    func load() -> AuthToken? {
        token.withLock { $0 }
    }

    func save(_ token: AuthToken?) {
        self.token.withLock { $0 = token }
    }
}

extension AuthToken {
    static let old = AuthToken(accessToken: "old-access", refreshToken: "old-refresh", tokenType: "Bearer")
    static let new = AuthToken(accessToken: "new-access", refreshToken: "new-refresh", tokenType: "Bearer")
}
