import Foundation
import Moya
import Testing
@testable import CoreNetwork

/// 0단계: Moya 호출 → 디코딩 → APIError 변환
///
/// Moya stub은 Alamofire `Session`을 거치지 않는다.
/// 인터셉터가 들어오는 4단계부터는 이 방식으로 검증할 수 없다.
struct APIServiceTests {
    @Test func 성공_응답을_snake_case로_디코딩한다() async throws {
        let json = #"{"success": true, "data": {"user_name": "yg"}, "message": null, "code": null}"#
        let service = APIService.stub(.networkResponse(200, Data(json.utf8)))
        
        let response = try await service.request(StubTarget(), responseType: User.self)
        
        #expect(response.success)
        #expect(response.data == User(userName: "yg"))
    }
    
    @Test func 성공_코드가_아니면_httpError와_서버_메시지를_던진다() async throws {
        let json = #"{"success": false, "data": null, "message": "서버 오류", "code": "E500"}"#
        let service = APIService.stub(.networkResponse(500, Data(json.utf8)))
        
        let error = await #expect(throws: APIError.self) {
            try await service.request(StubTarget(), responseType: User.self)
        }
        
        guard case .httpError(let statusCode, let message) = error else {
            Issue.record("httpError가 아님: \(String(describing: error))")
            return
        }
        #expect(statusCode == 500)
        #expect(message == "서버 오류")
    }
    
    @Test func 응답_형식이_다르면_decodingError를_던진다() async throws {
        let service = APIService.stub(.networkResponse(200, Data("not json".utf8)))
        
        let error = await #expect(throws: APIError.self) {
            try await service.request(StubTarget(), responseType: User.self)
        }
        
        guard case .decodingError = error else {
            Issue.record("decodingError가 아님: \(String(describing: error))")
            return
        }
    }
    
    @Test func 연결에_실패하면_networkError를_던진다() async throws {
        let offline = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let service = APIService.stub(.networkError(offline))
        
        let error = await #expect(throws: APIError.self) {
            try await service.request(StubTarget(), responseType: User.self)
        }
        
        guard case .networkError = error else {
            Issue.record("networkError가 아님: \(String(describing: error))")
            return
        }
    }
    
    @Suite struct requestData_테스트 {
        @Test func 성공시_Data를_그대로_반환한다() async throws {
            let byte = Data([0xFF, 0xD8, 0x00])
            let service = APIService.stub(.networkResponse(200, byte))
            
            let response = try await service.requestData(StubTarget())
            
            #expect(response == byte)
        }
        
        @Test func 실패시_httpError에_서버_메시지를_담는다() async throws {
            let json = #"{"success": false, "data": null, "message": "서버 오류", "code": "E500"}"#
            let service = APIService.stub(.networkResponse(500, Data(json.utf8)))

            let error = await #expect(throws: APIError.self) {
                try await service.requestData(StubTarget())
            }

            guard case .httpError(let statusCode, let message) = error else {
                Issue.record("httpError가 아님: \(String(describing: error))")
                return
            }
            #expect(statusCode == 500)
            #expect(message == "서버 오류")
        }

        /// 파일 다운로드 중 서버 오류: 본문이 JSON이 아니어도 서버가 응답했으므로 httpError
        @Test func 본문이_JSON이_아니어도_httpError를_던진다() async throws {
            let service = APIService.stub(.networkResponse(500, Data([0xFF, 0xD8, 0x00])))

            let error = await #expect(throws: APIError.self) {
                try await service.requestData(StubTarget())
            }

            guard case .httpError(let statusCode, let message) = error else {
                Issue.record("httpError가 아님: \(String(describing: error))")
                return
            }
            #expect(statusCode == 500)
            #expect(message == nil)
        }
    }

    /// 3단계: Task를 취소하면 Moya 요청도 취소되고 `.cancelled`가 나온다.
    ///
    /// 지연 stub은 Moya 안에서 취소되므로 `NSURLErrorCancelled` 경로만 검증한다.
    /// `AFError.explicitlyCancelled` 경로는 `URLProtocol` mock으로 4단계에서 검증한다.
    @Suite struct 취소_테스트 {
        @Test func 요청_중에_Task를_취소하면_cancelled를_던진다() async throws {
            let json = #"{"success": true, "data": {"user_name": "yg"}, "message": null, "code": null}"#
            let service = APIService.stub(.networkResponse(200, Data(json.utf8)), behavior: .delayed(seconds: 1))

            let task = _Concurrency.Task {
                try await service.request(StubTarget(), responseType: User.self)
            }
            try await _Concurrency.Task.sleep(for: .milliseconds(100))   // 요청이 출발할 시간을 줌
            task.cancel()

            let error = await #expect(throws: APIError.self) {
                try await task.value
            }
            guard case .cancelled = error else {
                Issue.record("cancelled가 아님: \(String(describing: error))")
                return
            }
        }

        /// 이미 취소된 Task에서는 onCancel이 요청보다 먼저 불린다.
        @Test func 이미_취소된_Task에서_불러도_cancelled를_던진다() async throws {
            let json = #"{"success": true, "data": {"user_name": "yg"}, "message": null, "code": null}"#
            let service = APIService.stub(.networkResponse(200, Data(json.utf8)), behavior: .delayed(seconds: 1))

            let task = _Concurrency.Task {
                withUnsafeCurrentTask { $0?.cancel() }   // 요청 전에 스스로 취소
                return try await service.request(StubTarget(), responseType: User.self)
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

    /// nginx·로드밸런서가 HTML 에러 페이지를 돌려주는 경우.
    /// 네트워크 오류로 분류되면 6단계의 "네트워크 오류면 세션 유지" 구분이 깨진다.
    @Test func 본문이_HTML인_502도_httpError를_던진다() async throws {
        let html = "<html><body>502 Bad Gateway</body></html>"
        let service = APIService.stub(.networkResponse(502, Data(html.utf8)))

        let error = await #expect(throws: APIError.self) {
            try await service.request(StubTarget(), responseType: User.self)
        }

        guard case .httpError(let statusCode, let message) = error else {
            Issue.record("httpError가 아님: \(String(describing: error))")
            return
        }
        #expect(statusCode == 502)
        #expect(message == nil)
    }
}
