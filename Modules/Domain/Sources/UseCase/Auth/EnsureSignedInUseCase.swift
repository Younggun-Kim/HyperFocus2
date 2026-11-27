//
//  EnsureSignedInUseCase.swift
//  Domain
//
//  Created by 김영건 on 11/26/26.
//

import Dependencies
import DependenciesMacros

@DependencyClient
public struct EnsureSignedInUseCase: Sendable {
    public var execute: @Sendable () async -> Result<Void, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var ensureSignedInUseCase: EnsureSignedInUseCase {
        get { self[EnsureSignedInUseCase.self] }
        set { self[EnsureSignedInUseCase.self] = newValue }
    }
}

extension EnsureSignedInUseCase: DependencyKey {
    
    public static let liveValue = Self(
        execute: {
            @Dependency(\.authRepository) var authRepository
            
            if authRepository.hasToken() { return .success(()) }
            
            return await authRepository.signInAnonymously()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
