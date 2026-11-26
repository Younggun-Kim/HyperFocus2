//
//  APIService.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Alamofire
import Foundation

/// Data가 쓰는 통신 진입점. Alamofire 타입이 드러나지 않도록 `APIEndpoint`만 받는다.
/// Data의 테스트는 이 프로토콜의 가짜 구현을 넣어 Repository를 검증한다.
///
/// 구현할 것은 `requestData` 하나다. 디코딩과 봉투 열기는 아래 extension이 맡아서,
/// 가짜 구현이 실제와 다르게 동작할 수 없다.
public protocol APIServiceProtocol: Sendable {
    /// 요청을 보내고 성공(2xx) 응답의 본문을 그대로 돌려준다.
    func requestData(_ endpoint: some APIEndpoint) async throws -> Data
}

public extension APIServiceProtocol {
    /// 요청을 보내고 응답 봉투(`APIResponse`)를 열어 `data`를 돌려준다.
    ///
    /// 2xx인데 봉투가 약속과 다르면 `APIError.decodingError`를 던진다(`APIResponse.open`).
    /// 본문을 쓰지 않는 API는 `EmptyResponse`로 받는다.
    func request<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response {
        let data = try await requestData(endpoint)
        return try APIResponse<E.Response>.open(data, path: endpoint.path)
    }
}

public struct APIService: APIServiceProtocol {
    private let baseURL: URL
    private let session: Session
    private let tokenManager: TokenManager

    /// - Parameter baseURL: 모든 `APIEndpoint.path` 앞에 붙는 주소. 환경별 값은 App의 xcconfig에서 온다.
    public init(
        baseURL: URL,
        tokenManager: TokenManager,
        configuration: URLSessionConfiguration = .af.default
    ) {
        self.baseURL = baseURL
        self.session = Session(configuration: configuration)
        self.tokenManager = tokenManager
    }

    /// 이 함수를 부른 Task가 취소되면 요청도 취소되고 `APIError.cancelled`를 던진다.
    public func requestData(_ endpoint: some APIEndpoint) async throws -> Data {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.urlRequest(baseURL: baseURL)
        } catch {
            throw APIError.decodingError("\(endpoint.path): 요청 본문 인코딩 실패 (\(String(describing: error)))")
        }
        NetworkLog.willSend(urlRequest, endpoint: endpoint)

        let request = session
            // 인터셉터는 토큰을 붙이고, 401이면 갱신 후 다시 보낸다. 재시도는 아래 await 안에서 끝난다.
            .request(urlRequest, interceptor: endpoint.requiresAuth ? tokenManager.interceptor : nil)
            // 상태 코드만 본다. 2xx가 아니어야 에러가 되고, 에러가 돼야 인터셉터가 401을 보고 갱신한다.
            .validate(statusCode: 200..<300)

        // Alamofire의 async API(`serializingData` 등)를 쓰지 않는다. 직렬화기를 거치면 실패한 요청이
        // 인터셉터에 한 번 더 넘어가서, 세션 만료(`sessionExpired`)가 토큰 없음(`missingCredential`)으로 덮인다.
        let response = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                request.response(queue: .global()) { continuation.resume(returning: $0) }
            }
        } onCancel: {
            // 취소해도 위의 handler는 `explicitlyCancelled`로 한 번 불린다.
            request.cancel()
        }

        switch response.result {
        case .success(let body):
            // 2xx면 본문이 비어 있어도 그대로 돌려준다. 빈 본문을 어떻게 볼지는 `APIResponse.open`이 정한다.
            let data = body ?? Data()
            NetworkLog.didReceive(data, statusCode: response.response?.statusCode, endpoint: endpoint)
            return data

        case .failure(let error):
            let apiError = APIError.from(error, response: response.response, body: response.data)
            NetworkLog.didFail(apiError, body: response.data, endpoint: endpoint)
            throw apiError
        }
    }
}

extension APIEndpoint {
    /// 실제로 보낼 요청을 만든다. 본문은 키를 바꾸지 않고 JSON으로 인코딩한다.
    func urlRequest(baseURL: URL) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        for (field, value) in NetworkHeader.basic {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }
}
