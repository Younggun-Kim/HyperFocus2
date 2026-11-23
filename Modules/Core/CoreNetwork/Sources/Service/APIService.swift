//
//  APIService.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation
import Alamofire
import Moya
import Synchronization


public protocol APIServiceProtocol {
    /// 요청 실행 (APIResponse 래핑)
    func request<T: BaseTarget, D: Decodable & Sendable>(
        _ target: T,
        responseType: D.Type
    ) async throws -> APIResponse<D>
    
    /// Raw Data 요청 (파일 다운로드 등)
    func requestData<T: BaseTarget>(_ target: T) async throws -> Data
}

public struct APIService: APIServiceProtocol {
    private let provider: MoyaProvider<MultiTarget>
    private let authProvider: MoyaProvider<MultiTarget>

    public init(
        tokenManager: TokenManager,
        configuration: URLSessionConfiguration = .af.default
    ) {
        self.init(
            provider: MoyaProvider(
                session: Session(configuration: configuration, startRequestsImmediately: false)
            ),
            authProvider: MoyaProvider(
                session: Session(
                    configuration: configuration,
                    startRequestsImmediately: false,
                    interceptor: tokenManager.interceptor
                )
            )
        )
    }

    /// `requiresAuth`에 따라 `authProvider`(인터셉터 있음)와 `provider`(없음) 중 하나로 보낸다.
    init(provider: MoyaProvider<MultiTarget>, authProvider: MoyaProvider<MultiTarget>) {
        self.provider = provider
        self.authProvider = authProvider
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
    
    public func requestData<T: BaseTarget>(_ target: T) async throws -> Data {
        try await send(target)
    }
    
    /// 요청 하나의 취소 상태. `send`의 operation과 `onCancel`이 함께 본다.
    private enum RequestState {
        /// 아직 요청을 보내지 않았고, 취소도 되지 않음
        case idle
        /// 요청이 나가는 중. 취소할 때 쓸 손잡이를 들고 있음
        case requesting(Cancellable)
        /// `onCancel`이 먼저 불림. 이후에 나가는 요청은 바로 취소해야 함
        case cancelled
    }

    private func send<T: BaseTarget>(_ target: T) async throws -> Data {
        // 요청마다 새로 만드는 상자. operation과 onCancel이 서로 다른 스레드에서 열 수 있어서 Mutex로 감싼다.
        let state = Mutex<RequestState>(.idle)
        let provider = target.requiresAuth ? authProvider : self.provider

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let cancellable = provider.request(MultiTarget(target)) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response.data)

                    case .failure(let error):
                        continuation.resume(throwing: APIError.from(error))
                    }
                }

                state.withLock { state in
                    switch state {
                    case .idle:
                        state = .requesting(cancellable)
                    case .cancelled:
                        // onCancel이 먼저 불렸다. 담지 않고 바로 취소한다.
                        cancellable.cancel()
                    case .requesting:
                        // 요청은 한 번만 보내므로 올 수 없음
                        break
                    }
                }
            }
        } onCancel: {
            state.withLock { state in
                switch state {
                case .requesting(let cancellable):
                    cancellable.cancel()
                case .idle:
                    // 아직 요청 전이다. 나중에 담으려는 쪽이 보도록 적어 둔다.
                    state = .cancelled
                case .cancelled:
                    break
                }
            }
        }
    }
}
