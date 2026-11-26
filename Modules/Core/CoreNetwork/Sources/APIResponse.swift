//
//  APIResponse.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation

/// 본문을 쓰지 않는 API의 응답. 이 타입으로 받으면 `data`가 없어도 성공이다.
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

extension APIResponse {
    /// 성공(2xx) 응답의 본문에서 봉투를 열어 `data`를 꺼낸다.
    ///
    /// 2xx인데 봉투가 약속과 다르면 서버 계약 위반이므로 `APIError.decodingError`를 던진다.
    /// - 봉투 형식이 아니다
    /// - `success`가 `false`다
    /// - `data`가 없다. 단, `EmptyResponse`로 받으면 본문이 비었거나 `data`가 없어도 성공이다.
    ///
    /// - Parameter path: 에러에 남겨 로그에서 어떤 API였는지 구분한다.
    static func open(_ body: Data, path: String) throws(APIError) -> T {
        if body.isEmpty, let empty = EmptyResponse() as? T {
            return empty
        }

        let envelope: APIResponse<T>
        do {
            envelope = try JSONDecoder.api.decode(APIResponse<T>.self, from: body)
        } catch {
            throw .decodingError("\(path): \(String(describing: error))")
        }

        guard envelope.success else {
            throw .decodingError("\(path): 2xx인데 success가 false다 (message: \(envelope.message ?? "없음"))")
        }
        if let data = envelope.data {
            return data
        }
        if let empty = EmptyResponse() as? T {
            return empty
        }
        throw .decodingError("\(path): 응답에 data가 없다")
    }
}
