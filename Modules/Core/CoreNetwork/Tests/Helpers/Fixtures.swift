//
//  Fixtures.swift
//  CoreNetworkTests
//
//  Created by 김영건 on 11/21/26.
//

import Foundation
import Moya
@testable import CoreNetwork

struct User: Decodable, Sendable, Equatable {
    let userName: String
}

struct StubTarget: BaseTarget {
    /// `MockURLProtocol.register`가 돌려준 host. Moya stub에서는 쓰이지 않는다.
    var host = "example.com"
    var requiresAuth = true

    var baseURL: URL { URL(string: "https://\(host)")! }
    var path: String { "/stub" }
    var method: Moya.Method { .get }
    var task: Moya.Task { .requestPlain }
}

extension APIService {
    /// 모든 요청에 `sample`을 돌려주는 서비스. 기본은 즉시 응답한다.
    ///
    /// Moya stub은 Alamofire `Session`을 거치지 않는다. 인터셉터를 검증할 때는 `MoyaProvider.mock()`을 쓴다.
    static func stub(
        _ sample: EndpointSampleResponse,
        behavior: StubBehavior = .immediate
    ) -> APIService {
        let provider = MoyaProvider<MultiTarget>(
            endpointClosure: { target in
                Moya.Endpoint(
                    url: URL(target: target).absoluteString,
                    sampleResponseClosure: { sample },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers
                )
            },
            stubClosure: { _ in behavior }
        )
        return APIService(baseURL: .stub, provider: provider, authProvider: provider)
    }
}

extension URL {
    /// `APIEndpoint`로 보낼 때 붙는 baseURL. `StubTarget`은 자기 baseURL을 쓰므로 쓰이지 않는다.
    static let stub = URL(string: "https://example.com")!
}

extension APIService {
    /// 인터셉터 테스트용. baseURL은 `StubTarget`이 직접 정하므로 고정값을 넣는다.
    init(tokenManager: TokenManager, configuration: URLSessionConfiguration) {
        self.init(baseURL: .stub, tokenManager: tokenManager, configuration: configuration)
    }
}

/// `APIEndpoint`가 `EndpointTarget`으로 바뀌는지 확인하는 API
struct StubEndpoint: APIEndpoint {
    typealias Response = User

    struct Body: Encodable, Sendable { let name: String }

    var path = "/endpoint"
    var method: HTTPMethod = .get
    var body: (any Encodable & Sendable)?
    var requiresAuth = true
}
