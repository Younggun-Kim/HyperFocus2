//
//  URLSessionConfiguration+Mock.swift
//  CoreNetworkTests
//
//  Created by 김영건 on 11/21/26.
//

import Foundation

extension URLSessionConfiguration {
    /// `MockURLProtocol`로 응답하는 configuration.
    ///
    /// `APIService(tokenManager:configuration:)`에 넘기면 stub이 아닌 실제 Alamofire `Session`을 거치므로
    /// 인터셉터까지 실행된다.
    static var mock: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return configuration
    }
}
