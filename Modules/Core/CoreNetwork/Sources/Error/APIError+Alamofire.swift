//
//  APIError+Alamofire.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation
import Alamofire


extension APIError {
    
    /// 서버 응답에서 메시지 파싱
    private static func parseServerMessage(from data: Data) -> String? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if let errorResponse = try? decoder.decode(APIResponse<EmptyResponse>.self, from: data) {
            return errorResponse.message
        }
        
        return nil
    }
    
    /// 취소 에러는 경로에 따라 두 가지로 온다.
    /// - Alamofire 요청을 취소: `AFError.explicitlyCancelled`
    /// - URLSession 쪽에서 취소가 먼저 보임: `NSURLErrorCancelled`를 감싼 `sessionTaskFailed`
    private static func isCancellation(_ error: AFError) -> Bool {
        if error.isExplicitlyCancelledError {
            return true
        }
        return (error.underlyingError as? URLError)?.code == .cancelled
    }

    /// 토큰이 없으면 `AuthenticationInterceptor`가 요청을 보내지 않고
    /// `AFError.requestAdaptationFailed(AuthenticationError.missingCredential)`로 끝낸다.
    /// 세션 만료로 토큰이 지워진 뒤 401이 도착하면 `requestRetryFailed(missingCredential)`로 온다.
    private static func isMissingCredential(_ error: AFError) -> Bool {
        switch error {
        case .requestAdaptationFailed(let underlying):
            return (underlying as? AuthenticationError) == .missingCredential
        case .requestRetryFailed(let retryError, _):
            return (retryError as? AuthenticationError) == .missingCredential
        default:
            return false
        }
    }

    /// 갱신이 실패하면 Alamofire가 `TokenAuthenticator`가 넘긴 에러를 감싸서 돌려준다.
    /// - 401을 받고 재시도를 기다리던 요청: `requestRetryFailed(retryError:)`
    /// - 갱신 중에 출발을 기다리던 요청: `requestAdaptationFailed`
    private static func refreshFailure(_ error: AFError) -> APIError? {
        switch error {
        case .requestRetryFailed(let retryError, _):
            return retryError as? APIError
        case .requestAdaptationFailed(let underlying):
            return underlying as? APIError
        default:
            return nil
        }
    }

    /// Alamofire가 돌려준 실패를 통신 사실로 바꾼다.
    ///
    /// - Parameters:
    ///   - response: 서버가 응답했다면 그 응답. 없으면 서버에 닿지 못했거나 보내지 않은 것이다.
    ///   - body: 실패 응답의 본문. 서버 메시지를 읽는다.
    static func from(_ error: AFError, response: HTTPURLResponse?, body: Data?) -> APIError {
        // 갱신 실패는 원래 요청의 401 응답을 들고 오므로 응답 검사보다 먼저 본다.
        if let refreshError = refreshFailure(error) {
            return refreshError
        }

        if isMissingCredential(error) {
            return .tokenNotFound
        }

        // 실패한 응답이 있다 = 서버까지 갔다 왔다. 본문이 JSON이 아니어도(HTML 에러 페이지, 파일 등) httpError.
        if let response, !(200..<300).contains(response.statusCode) {
            return .httpError(
                statusCode: response.statusCode,
                message: body.flatMap(parseServerMessage)
            )
        }

        if isCancellation(error) {
            return .cancelled
        }

        return .networkError(error.localizedDescription)
    }
}
