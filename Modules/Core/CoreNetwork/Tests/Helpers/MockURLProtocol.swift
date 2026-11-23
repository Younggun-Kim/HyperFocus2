//
//  MockURLProtocol.swift
//  CoreNetworkTests
//
//  Created by 김영건 on 11/21/26.
//

import Foundation
import Synchronization
import Testing

final class MockURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    /// host → handler. `startLoading`은 URLSession 내부 스레드에서 불리므로 Mutex로 감싼다.
    private static let handlers = Mutex<[String: Handler]>([:])

    /// handler를 등록하고, 요청에 쓸 고유 host를 돌려준다.
    static func register(_ handler: @escaping Handler) -> String {
        let host = "\(UUID().uuidString.lowercased()).mock"
        handlers.withLock { $0[host] = handler }
        return host
    }

    static func unregister(_ host: String) {
        _ = handlers.withLock { $0.removeValue(forKey: host) }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let host = request.url?.host() ?? ""
        guard let handler = Self.handlers.withLock({ $0[host] }) else {
            Issue.record("handler가 등록되지 않은 host: \(host)")
            // 어떤 경로든 client에게 끝을 알려야 한다. 안 그러면 요청이 영원히 끝나지 않는다.
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    /// 요청이 취소되면 불린다. 지금은 응답을 바로 주므로 할 일이 없다.
    override func stopLoading() {}
}

extension HTTPURLResponse {
    /// mock handler에서 쓰는 응답. 실패할 수 있는 init을 테스트에서 매번 풀지 않도록 감싼다.
    static func mock(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
