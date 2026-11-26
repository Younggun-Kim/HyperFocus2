import Foundation
import Testing
@testable import CoreNetwork

/// 요청 → 디코딩 → `APIError` 변환을 공개 API로 검증한다.
///
/// `MockURLProtocol`로 응답하므로 실제 Alamofire `Session`을 거친다.
/// 통신 라이브러리를 어떻게 쓰는지는 보지 않는다. 구현이 바뀌어도 그대로 통과해야 한다.
struct APIServiceTests {
    private static let userJSON = #"{"success": true, "data": {"user_name": "yg"}, "message": null, "code": null}"#

    @Test func 성공_응답을_snake_case로_디코딩한다() async throws {
        let service = APIService.responding(200, Self.userJSON)

        let response = try await service.request(StubEndpoint<User>()).get()

        #expect(response == User(userName: "yg"))
    }

    @Test func 성공_코드가_아니면_httpError와_서버_메시지를_던진다() async throws {
        let json = #"{"success": false, "data": null, "message": "서버 오류", "code": "E500"}"#
        let service = APIService.responding(500, json)

        let error = await #expect(throws: APIError.self) {
            try await service.request(StubEndpoint<User>()).get()
        }

        guard case .httpError(let statusCode, let message) = error else {
            Issue.record("httpError가 아님: \(String(describing: error))")
            return
        }
        #expect(statusCode == 500)
        #expect(message == "서버 오류")
    }

    @Test func 응답_형식이_다르면_decodingError를_던진다() async throws {
        let service = APIService.responding(200, "not json")

        let error = await #expect(throws: APIError.self) {
            try await service.request(StubEndpoint<User>()).get()
        }

        guard case .decodingError = error else {
            Issue.record("decodingError가 아님: \(String(describing: error))")
            return
        }
    }

    @Test(arguments: [URLError.Code.notConnectedToInternet, .timedOut, .cannotConnectToHost])
    func 연결에_실패하면_networkError를_던진다(code: URLError.Code) async throws {
        let service = APIService.failing(URLError(code))

        let error = await #expect(throws: APIError.self) {
            try await service.request(StubEndpoint<User>()).get()
        }

        guard case .networkError = error else {
            Issue.record("networkError가 아님: \(String(describing: error))")
            return
        }
    }

    /// nginx·로드밸런서가 HTML 에러 페이지를 돌려주는 경우.
    /// 네트워크 오류로 분류되면 "네트워크 오류면 세션 유지" 구분이 깨진다.
    @Test func 본문이_HTML인_502도_httpError를_던진다() async throws {
        let service = APIService.responding(502, "<html><body>502 Bad Gateway</body></html>")

        let error = await #expect(throws: APIError.self) {
            try await service.request(StubEndpoint<User>()).get()
        }

        guard case .httpError(let statusCode, let message) = error else {
            Issue.record("httpError가 아님: \(String(describing: error))")
            return
        }
        #expect(statusCode == 502)
        #expect(message == nil)
    }

    @Suite struct requestData_테스트 {
        @Test func 성공시_Data를_그대로_반환한다() async throws {
            let byte = Data([0xFF, 0xD8, 0x00])
            let service = APIService.responding(200, byte)

            let response = try await service.requestData(StubEndpoint<User>()).get()

            #expect(response == byte)
        }

        @Test func 실패시_httpError에_서버_메시지를_담는다() async throws {
            let json = #"{"success": false, "data": null, "message": "서버 오류", "code": "E500"}"#
            let service = APIService.responding(500, json)

            let error = await #expect(throws: APIError.self) {
                try await service.requestData(StubEndpoint<User>()).get()
            }

            guard case .httpError(let statusCode, let message) = error else {
                Issue.record("httpError가 아님: \(String(describing: error))")
                return
            }
            #expect(statusCode == 500)
            #expect(message == "서버 오류")
        }

        /// 파일 다운로드 중 서버 오류: 본문이 JSON이 아니어도 서버가 응답했으므로 httpError
        @Test(arguments: [Data([0xFF, 0xD8, 0x00]), Data()])
        func 본문이_JSON이_아니어도_httpError를_던진다(body: Data) async throws {
            let service = APIService.responding(500, body)

            let error = await #expect(throws: APIError.self) {
                try await service.requestData(StubEndpoint<User>()).get()
            }

            guard case .httpError(let statusCode, let message) = error else {
                Issue.record("httpError가 아님: \(String(describing: error))")
                return
            }
            #expect(statusCode == 500)
            #expect(message == nil)
        }
    }

    /// 2xx인데 봉투가 약속과 다르면 서버 계약 위반이다. `decodingError`로 던진다.
    @Suite struct 봉투_열기 {
        @Test(arguments: [
            #"{"success": true, "data": null}"#,
            #"{"success": true}"#,
        ])
        func data가_없으면_decodingError를_던진다(json: String) async throws {
            let service = APIService.responding(200, json)

            let error = await #expect(throws: APIError.self) {
                try await service.request(StubEndpoint<User>()).get()
            }

            guard case .decodingError(let message) = error else {
                Issue.record("decodingError가 아님: \(String(describing: error))")
                return
            }
            #expect(message.contains("/endpoint"))   // 로그에서 어떤 API였는지 구분한다
        }

        @Test(arguments: [
            #"{"success": true, "data": null}"#,
            #"{"success": true}"#,
            #"{"success": true, "data": {"id": "1"}}"#,
        ])
        func EmptyResponse로_받으면_data가_없어도_성공한다(json: String) async throws {
            let service = APIService.responding(200, json)

            _ = try await service.request(StubEndpoint<EmptyResponse>()).get()
        }

        @Test(arguments: [200, 204])
        func EmptyResponse로_받으면_본문이_비어도_성공한다(statusCode: Int) async throws {
            let service = APIService.responding(statusCode, Data())

            _ = try await service.request(StubEndpoint<EmptyResponse>()).get()
        }

        @Test(arguments: [200, 204])
        func 본문이_비었는데_data를_기대하면_decodingError를_던진다(statusCode: Int) async throws {
            let service = APIService.responding(statusCode, Data())

            let error = await #expect(throws: APIError.self) {
                try await service.request(StubEndpoint<User>()).get()
            }

            guard case .decodingError = error else {
                Issue.record("decodingError가 아님: \(String(describing: error))")
                return
            }
        }

        @Test func 성공_코드인데_success가_false면_decodingError에_서버_메시지를_담는다() async throws {
            let json = #"{"success": false, "data": null, "message": "처리할 수 없습니다", "code": "E001"}"#
            let service = APIService.responding(200, json)

            let error = await #expect(throws: APIError.self) {
                try await service.request(StubEndpoint<EmptyResponse>()).get()
            }

            guard case .decodingError(let message) = error else {
                Issue.record("decodingError가 아님: \(String(describing: error))")
                return
            }
            #expect(message.contains("처리할 수 없습니다"))
        }
    }

    /// Task를 취소하면 요청도 취소되고 `.cancelled`가 나온다.
    /// 응답을 기다리는 중에 취소하는 경우는 `APIInterceptorTests`에 있다.
    @Suite struct 취소_테스트 {
        /// 이미 취소된 Task에서는 취소가 요청보다 먼저 일어난다.
        @Test(arguments: [true, false])
        func 이미_취소된_Task에서_불러도_cancelled를_던진다(requiresAuth: Bool) async throws {
            let service = APIService.responding(200, APIServiceTests.userJSON)

            let task = _Concurrency.Task {
                withUnsafeCurrentTask { $0?.cancel() }   // 요청 전에 스스로 취소
                return try await service.request(StubEndpoint<User>(requiresAuth: requiresAuth)).get()
            }

            let error = await #expect(throws: APIError.self) {
                try await task.value
            }
            guard case .cancelled = error else {
                Issue.record("cancelled가 아님: \(String(describing: error))")
                return
            }
        }
    }
}
