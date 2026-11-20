//
//  APIInterceptorTests.swift
//  CoreNetworkTests
//
//  Created by 김영건 on 11/20/26.
//

import Foundation
import Testing
import Moya
@testable import CoreNetwork

/// 4단계: Alamofire `Session`을 거치는 요청을 `MockURLProtocol`로 검증한다.
struct APIInterceptorTests {
    let service = APIService(provider: .mock())
    
    @Test func MockURLProtocol의_응답을_디코딩한다() async throws {
        let json = #"{"success": true, "data": {"user_name": "yg"}, "message": null, "code": null}"#
        let host = MockURLProtocol.register { request in
            (.mock(for: request, statusCode: 200), Data(json.utf8))
        }
        defer { MockURLProtocol.unregister(host) }
        
        let response = try await service.request(StubTarget(host: host), responseType: User.self)
        
        #expect(response.success)
        #expect(response.data == User(userName: "yg"))
    }
}
