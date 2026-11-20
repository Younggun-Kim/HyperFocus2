//
//  MoyaProvider+Mock.swift
//  CoreNetworkTests
//
//  Created by 김영건 on 11/21/26.
//

import Foundation
import Moya

extension MoyaProvider {
    /// `MockURLProtocol`로 응답하는 provider.
    ///
    /// stub을 끈 진짜 provider다(`stubClosure` 기본값 `neverStub`).
    /// stub이 켜져 있으면 Moya가 `Session`을 거치지 않으므로 mock과 인터셉터가 실행되지 않는다.
    static func mock() -> MoyaProvider<Target> {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        // Moya가 직접 resume()을 부르므로 false로 둔다 (Moya 기본 Session과 같음).
        let session = Session(configuration: configuration, startRequestsImmediately: false)
        return MoyaProvider<Target>(session: session)
    }
}
