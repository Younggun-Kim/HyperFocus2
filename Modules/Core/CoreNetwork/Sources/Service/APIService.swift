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


/// Data가 쓰는 통신 진입점. Moya 타입이 드러나지 않도록 `APIEndpoint`만 받는다.
/// Data의 테스트는 이 프로토콜의 가짜 구현을 넣어 Repository를 검증한다.
public protocol APIServiceProtocol: Sendable {
    /// 요청 실행 (APIResponse 래핑)
    func request<D: Decodable & Sendable>(
        _ endpoint: some APIEndpoint,
        responseType: D.Type
    ) async throws -> APIResponse<D>

    /// Raw Data 요청 (파일 다운로드 등)
    func requestData(_ endpoint: some APIEndpoint) async throws -> Data
}

/// `MoyaProvider`가 `Sendable`을 채택하지 않아 `@unchecked`로 둔다.
/// 저장 속성은 모두 `let`이고, provider는 요청마다 새 상태를 만들어 여러 스레드에서 불러도 된다.
public struct APIService: APIServiceProtocol, @unchecked Sendable {
    private let baseURL: URL
    private let provider: MoyaProvider<MultiTarget>
    private let authProvider: MoyaProvider<MultiTarget>

    /// - Parameter baseURL: 모든 `APIEndpoint.path` 앞에 붙는 주소. 환경별 값은 App의 xcconfig에서 온다.
    public init(
        baseURL: URL,
        tokenManager: TokenManager,
        configuration: URLSessionConfiguration = .af.default
    ) {
        self.init(
            baseURL: baseURL,
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
    init(
        baseURL: URL,
        provider: MoyaProvider<MultiTarget>,
        authProvider: MoyaProvider<MultiTarget>
    ) {
        self.baseURL = baseURL
        self.provider = provider
        self.authProvider = authProvider
    }
    
    public func request<D: Decodable & Sendable>(
        _ endpoint: some APIEndpoint,
        responseType: D.Type
    ) async throws -> APIResponse<D> {
        try await request(EndpointTarget(baseURL: baseURL, endpoint: endpoint), responseType: responseType)
    }

    public func requestData(_ endpoint: some APIEndpoint) async throws -> Data {
        try await requestData(EndpointTarget(baseURL: baseURL, endpoint: endpoint))
    }

    /// CoreNetwork 안(테스트 포함)에서 `BaseTarget`을 직접 보낼 때 쓴다.
    func request<T: BaseTarget, D: Decodable & Sendable>(
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
    
    func requestData<T: BaseTarget>(_ target: T) async throws -> Data {
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
