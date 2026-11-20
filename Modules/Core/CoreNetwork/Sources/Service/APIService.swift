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
        let data = try await send(target)
        
        do {
            return try JSONDecoder.api.decode(APIResponse<D>.self, from: data)
        } catch {
            throw APIError.decodingError(String(describing: error))
        }
    }
    
    private func send<T: BaseTarget>(_ target: T) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(MultiTarget(target)) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response.data)
                    
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(error))
                }
            }
        }
    }
}
