//
//  APIError+Moya.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation
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
            // 응답이 있다 = 서버까지 갔다 왔다. 본문이 JSON이 아니어도(HTML 에러 페이지, 파일 등) httpError.
            // Moya는 validationType 실패를 .underlying(.statusCode, response)로 감싸서 여기로 온다.
            if let response {
                return .httpError(
                    statusCode: response.statusCode,
                    message: parseServerMessage(from: response.data)
                )
            }

            if (error as NSError).code == NSURLErrorCancelled {
                return .cancelled
            }
            
            return .networkError(error.localizedDescription)
        }
    }
}
