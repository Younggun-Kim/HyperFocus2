//
//  APIError+Reason.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation

extension APIError {
    
    // 완료 전송이 왜 실패했는지 한 단어로. `session_complete_deferred` 의 reason 에 실린다.
    var deferralReason: String {
        switch self {
        case .networkError: return "network"
        case .cancelled: return "cancelled"
        case .tokenNotFound, .sessionExpired: return "auth"
        case .decodingError: return "decoding"
        case .httpError(let statusCode, _):
            return statusCode >= 500 ? "server_error" : "http_\(statusCode)"
        case .unknown: return "unknown"
        }
    }
    
    var isServerUnreachable: Bool {
        switch self {
        case .networkError, .tokenNotFound:
            return true
        case .httpError(let statusCode, _):
            return statusCode >= 500
        case .decodingError, .unknown, .cancelled, .sessionExpired:
            return false
        }
    }
}
