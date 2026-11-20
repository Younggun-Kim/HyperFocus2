//
//  APIError.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//


import Foundation
import Moya

public enum APIError: LocalizedError {
    /// 네트워크 연결 실패
    case networkError(String)
    /// HTTP 상태 코드 에러
    case httpError(statusCode: Int, message: String?)
    /// 응답 파싱 실패
    case decodingError(String)
    /// 알 수 없는 에러
    case unknown(String)
    /// 요청 취소
    case cancelled
    /// 인증 토큰 없음
    case tokenNotFound
    /// 세션 만료 (토큰 갱신 실패)
    case sessionExpired
}

extension Locale {
    static var isKorean: Bool {
        Locale.preferredLanguages.first?.split(separator: "-").first == "ko"
    }
}

