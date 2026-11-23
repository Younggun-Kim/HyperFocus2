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
                Endpoint(
                    url: URL(target: target).absoluteString,
                    sampleResponseClosure: { sample },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers
                )
            },
            stubClosure: { _ in behavior }
        )
        return APIService(provider: provider, authProvider: provider)
    }
}
