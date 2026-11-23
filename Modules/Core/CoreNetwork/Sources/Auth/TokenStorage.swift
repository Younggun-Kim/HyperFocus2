//
//  TokenStorage.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/23/26.
//

/// 토큰을 영구 저장하는 곳. 구현은 Data 계층이 주입한다.
public protocol TokenStorage: Sendable {
    func load() -> AuthToken?
    func save(_ token: AuthToken?)
}
