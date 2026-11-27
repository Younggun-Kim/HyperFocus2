//
//  FetchProfileUseCase.swift
//  Domain
//
//  Created by 김영건 on 11/27/26.
//

import Dependencies
import DependenciesMacros

@DependencyClient
public struct FetchProfileUseCase: Sendable {
    public var execute: @Sendable  () async -> Result<Profile, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var fetchProfileUseCase: FetchProfileUseCase {
        get { self[FetchProfileUseCase.self] }
        set { self[FetchProfileUseCase.self] = newValue }
    }
}

extension FetchProfileUseCase: DependencyKey {
    public static let liveValue = Self(
        execute:  {
            @Dependency(\.authRepository) var authRepository
            
            return await authRepository.fetchProfile()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
