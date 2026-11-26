//
//  Fixtures.swift
//  CoreNetworkTests
//
//  Created by 김영건 on 11/21/26.
//

import Foundation
import Synchronization
import Testing
@testable import CoreNetwork

struct User: Decodable, Sendable, Equatable {
    let userName: String
}

/// 테스트가 공개 API(`APIEndpoint`)로 요청을 보낼 때 쓰는 API. `Response`는 테스트가 고른다.
struct StubEndpoint<Response: Decodable & Sendable>: APIEndpoint {
    struct Body: Encodable, Sendable {
        var name = "yg"
        /// 본문 키를 바꾸지 않고(camelCase 그대로) 보내는지 확인하는 값
        var userName = "yg"
    }

    var path = "/endpoint"
    var method: HTTPMethod = .get
    var body: (any Encodable & Sendable)?
    var requiresAuth = true
}

extension APIService {
    /// `MockURLProtocol.register`가 돌려준 host로 보내는 서비스.
    /// 실제 Alamofire `Session`을 거치므로 인터셉터까지 실행된다.
    init(host: String, tokenManager: TokenManager) {
        self.init(baseURL: URL(string: "https://\(host)")!, tokenManager: tokenManager, configuration: .mock)
    }

    /// 갱신이 일어나면 안 되는 테스트용
    static func mock(host: String, storage: any TokenStorage = InMemoryTokenStorage(.old)) -> APIService {
        APIService(host: host, tokenManager: .mock(storage: storage))
    }

    /// 모든 요청에 같은 응답을 돌려주는 서비스. 받은 요청은 `requests`에 쌓인다.
    ///
    /// host는 테스트마다 새로 만들어 겹치지 않으므로 등록을 해제하지 않는다.
    static func responding(
        _ statusCode: Int,
        _ body: Data,
        recordingTo requests: Locked<[URLRequest]> = Locked([])
    ) -> APIService {
        let host = MockURLProtocol.register { request in
            requests.withLock { $0.append(request) }
            return (.mock(for: request, statusCode: statusCode), body)
        }
        return .mock(host: host)
    }

    static func responding(
        _ statusCode: Int,
        _ json: String,
        recordingTo requests: Locked<[URLRequest]> = Locked([])
    ) -> APIService {
        responding(statusCode, Data(json.utf8), recordingTo: requests)
    }

    /// 서버에 닿지 못하고 실패하는 서비스
    static func failing(_ error: URLError) -> APIService {
        .mock(host: MockURLProtocol.register { _ in throw error })
    }
}

extension TokenManager {
    static func mock(storage: any TokenStorage) -> TokenManager {
        TokenManager(storage: storage) { _ in
            Issue.record("갱신하면 안 되는 테스트에서 갱신함")
            return .success(.new)
        }
    }
}

extension URLRequest {
    /// `URLProtocol`이 받은 요청은 본문이 `httpBody`가 아니라 `httpBodyStream`에 들어 있다.
    var bodyData: Data? {
        if let httpBody { return httpBody }
        guard let stream = httpBodyStream else { return nil }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

final class Locked<Value: Sendable>: Sendable {
    private let mutex: Mutex<Value>

    init(_ value: Value) {
        mutex = Mutex(value)
    }

    var value: Value {
        mutex.withLock { $0 }
    }

    func withLock(_ body: (inout Value) -> Void) {
        mutex.withLock { body(&$0) }
    }
}
