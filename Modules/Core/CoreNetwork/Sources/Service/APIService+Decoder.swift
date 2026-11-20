//
//  APIService+Decoder.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/20/26.
//

import Foundation

extension JSONDecoder {
    /// 모든 API 응답이 공유하는 디코더
    ///
    /// - 키: snake_case → camelCase
    /// - 날짜: `ServerDate.decode`
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(ServerDate.decode)
        return decoder
    }()
}

enum ServerDate {
    /// 시간대 표기가 있는 형식
    private static let withTimeZone = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    /// 시간대 표기가 없는 형식. 서버는 UTC로 보낸다.
    private static let withoutTimeZone = Date.ISO8601FormatStyle(timeZone: .gmt)
        .year().month().day()
        .dateSeparator(.dash)
        .time(includingFractionalSeconds: true)
        .timeSeparator(.colon)

    @Sendable
    static func decode(_ decoder: any Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        // 순서 중요: withoutTimeZone은 "+09:00"을 무시하고 UTC로 읽으므로 나중에 시도한다.
        if let date = try? Date(string, strategy: withTimeZone) {
            return date
        }
        if let date = try? Date(string, strategy: withoutTimeZone) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "지원하지 않는 날짜 형식: \(string)"
        )
    }
}
