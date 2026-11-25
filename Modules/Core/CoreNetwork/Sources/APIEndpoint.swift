//
//  APIEndpoint.swift
//  CoreNetwork
//

import Foundation

/// 바깥(Data)에 공개하는 HTTP 메서드. Moya 타입을 드러내지 않으려고 따로 둔다.
public enum HTTPMethod: Sendable, Equatable {
    case get
    case post
    case put
    case patch
    case delete
}

/// API 하나를 기술한다. Data의 `DataSource/Remote`가 API별로 채택한다.
///
/// 주소의 앞부분(baseURL)은 `APIService`가 붙인다. 여기서는 경로만 적는다.
/// Moya `TargetType`으로 바꾸는 일은 CoreNetwork 안에서만 한다.
public protocol APIEndpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    /// JSON으로 인코딩해 본문에 싣는다. `nil`이면 본문 없이 보낸다.
    var body: (any Encodable & Sendable)? { get }
    /// `true`면 `Authorization` 헤더를 붙여 보내고, 토큰이 없으면 요청을 보내지 않는다.
    var requiresAuth: Bool { get }
}

public extension APIEndpoint {
    var body: (any Encodable & Sendable)? { nil }
    var requiresAuth: Bool { true }
}
