//
//  APIError+UserMessage.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation

extension Error {
    var apiErrorMessage: String {
        if let apiError = self as? APIError {
            return apiError.userMessage
        }
        
        return localizedDescription
    }
}

extension APIError {
    
    public var errorDescription: String? {
        return userMessage
    }
    
    public var userMessage: String {
        
        if case .httpError(_, let message?) = self, !message.isEmpty {
            return message
        }
        return Locale.isKorean ? koreanUserMessage : englishUserMessage
    }
    
    private var koreanUserMessage: String {
        switch self {
        case .networkError:
            return "연결이 원활하지 않아요. 잠시 후 다시 시도해 주세요."
        case .httpError(let statusCode, _):
            return "일시적인 문제가 생겼어요. 잠시 후 다시 시도해 주세요. (\(statusCode))"
        case .decodingError:
            return "받아온 데이터를 읽지 못했어요. 잠시 후 다시 시도해 주세요."
        case .unknown:
            return "잠시 문제가 생겼어요. 다시 시도해 주세요."
        case .cancelled:
            return "요청이 취소되었습니다."
        case .sessionExpired:
            return "세션이 만료되었습니다. 다시 로그인합니다."
        case .tokenNotFound:
            return ""
        }
    }
    
    private var englishUserMessage: String {
        switch self {
        case .networkError:
            return "Connection seems unstable. Please try again in a moment."
        case .httpError(let statusCode, _):
            return "Something went wrong temporarily. Please try again in a moment. (\(statusCode))"
        case .decodingError:
            return "We couldn't read the data. Please try again in a moment."
        case .unknown:
            return "Something went wrong. Please try again."
        case .cancelled:
            return "The request was cancelled."
        case .sessionExpired:
            return "Your session has expired. Signing you in again."
        case .tokenNotFound:
            return ""
        }
    }
}
