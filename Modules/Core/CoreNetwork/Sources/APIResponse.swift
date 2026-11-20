//
//  APIResponse.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation

/// 빈 응답 (데이터가 없는 경우)
public struct EmptyResponse: Decodable, Sendable {
    public init() {}
}

/// 공통 API 응답 모델
public struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    /// 성공 여부
    public let success: Bool
    /// 응답 데이터
    public let data: T?
    /// 에러 메시지
    public let message: String?
    /// 에러 코드
    public let code: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case code
    }
    
    public init(success: Bool, data: T?, message: String? = nil, code: String? = nil) {
        self.success = success
        self.data = data
        self.message = message
        self.code = code
    }
}

