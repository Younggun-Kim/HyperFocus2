//
//  LogoutUseCase.swift
//  Domain
//
//  Created by 김영건 on 11/27/26.
//

import Dependencies
import DependenciesMacros


@DependencyClient
public struct LogoutUseCase: Sendable {
    public var execute: @Sendable  () async -> Result<Void, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var logoutUseCase: LogoutUseCase {
        get { self[LogoutUseCase.self] }
        set { self[LogoutUseCase.self] = newValue }
    }
}

extension LogoutUseCase: DependencyKey {
    public static let liveValue = Self(
        execute:  {
            @Dependency(\.authRepository) var authRepository

            return await authRepository.logout()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
