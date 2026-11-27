//
//  WithdrawUseCase.swift
//  Domain
//
//  Created by 김영건 on 11/27/26.
//

import Dependencies
import DependenciesMacros


@DependencyClient
public struct WithdrawUseCase: Sendable {
    public var execute: @Sendable  () async -> Result<Void, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var withdrawUseCase: WithdrawUseCase {
        get { self[WithdrawUseCase.self] }
        set { self[WithdrawUseCase.self] = newValue }
    }
}

extension WithdrawUseCase: DependencyKey {
    public static let liveValue = Self(
        execute:  {
            @Dependency(\.authRepository) var authRepository

            return await authRepository.withdraw()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
