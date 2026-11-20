//
//  APIService.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation
import Moya


public protocol APIServiceProtocol {
    /// 요청 실행 (APIResponse 래핑)
    func request<T: BaseTarget, D: Decodable & Sendable>(
        _ target: T,
        responseType: D.Type
    ) async throws -> APIResponse<D>
}

public struct APIService: APIServiceProtocol {
    private let provider: MoyaProvider<MultiTarget>

    public init(provider: MoyaProvider<MultiTarget>) {
        self.provider = provider
    }

    public func request<T: BaseTarget, D: Decodable & Sendable>(
        _ target: T,
        responseType: D.Type
    ) async throws -> APIResponse<D> {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(MultiTarget(target)) { result in
                switch result {
                case .success(let response):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let decoded = try decoder.decode(APIResponse<D>.self, from: response.data)
                        
                        continuation.resume(returning: decoded)
                    } catch {
                        continuation.resume(throwing: APIError.decodingError(error.localizedDescription))
                    }

                case .failure(let error):
                    continuation.resume(throwing: APIError.from(error))
                }
            }
        }
    }
}
