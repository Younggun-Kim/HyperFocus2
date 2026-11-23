//
//  APIError+Moya.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation
import Alamofire
import Moya


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
    /// - Moya stub, 또는 Alamofire 요청이 만들어지기 전에 취소: `NSURLErrorCancelled`
    /// - 진행 중인 Alamofire 요청을 취소: `AFError.explicitlyCancelled`
    private static func isCancellation(_ error: Error) -> Bool {
        if error.asAFError?.isExplicitlyCancelledError == true {
            return true
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }

    /// 토큰이 없으면 `AuthenticationInterceptor`가 요청을 보내지 않고
    /// `AFError.requestAdaptationFailed(AuthenticationError.missingCredential)`로 끝낸다.
    /// 세션 만료로 토큰이 지워진 뒤 401이 도착하면 `requestRetryFailed(missingCredential)`로 온다.
    private static func isMissingCredential(_ error: Error) -> Bool {
        switch error.asAFError {
        case .requestAdaptationFailed(let underlying)?:
            return (underlying as? AuthenticationError) == .missingCredential
        case .requestRetryFailed(let retryError, _)?:
            return (retryError as? AuthenticationError) == .missingCredential
        default:
            return false
        }
    }

    /// 갱신이 실패하면 Alamofire가 `TokenAuthenticator`가 넘긴 에러를 감싸서 돌려준다.
    /// - 401을 받고 재시도를 기다리던 요청: `requestRetryFailed(retryError:)`
    /// - 갱신 중에 출발을 기다리던 요청: `requestAdaptationFailed`
    private static func refreshFailure(_ error: Error) -> APIError? {
        switch error.asAFError {
        case .requestRetryFailed(let retryError, _)?:
            return retryError as? APIError
        case .requestAdaptationFailed(let underlying)?:
            return underlying as? APIError
        default:
            return nil
        }
    }

    public static func from(_ error: MoyaError) -> APIError {
        switch error {
        case .imageMapping, .jsonMapping, .stringMapping, .objectMapping:
            return .decodingError("응답 파싱에 실패했습니다.")
        case .encodableMapping:
            return .decodingError("요청 데이터 인코딩에 실패했습니다.")
        case .requestMapping(let message):
            return .networkError("요청 생성 실패: \(message)")
        case .parameterEncoding(let error):
            return .networkError("파라미터 인코딩 실패: \(error.localizedDescription)")
        case .statusCode(let response):
            let serverMessage = parseServerMessage(from: response.data)
            return .httpError(
                statusCode: response.statusCode,
                message: serverMessage
            )
        case .underlying(let error, let response):
            // 갱신 실패는 원래 요청의 401 응답을 들고 오므로 응답 검사보다 먼저 본다.
            if let refreshError = refreshFailure(error) {
                return refreshError
            }

            if isMissingCredential(error) {
                return .tokenNotFound
            }

            // 응답이 있다 = 서버까지 갔다 왔다. 본문이 JSON이 아니어도(HTML 에러 페이지, 파일 등) httpError.
            // Moya는 validationType 실패를 .underlying(.statusCode, response)로 감싸서 여기로 온다.
            if let response {
                return .httpError(
                    statusCode: response.statusCode,
                    message: parseServerMessage(from: response.data)
                )
            }

            if isCancellation(error) {
                return .cancelled
            }

            return .networkError(error.localizedDescription)
        }
    }
}
