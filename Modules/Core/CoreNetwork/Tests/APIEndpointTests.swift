import Foundation
import Moya
import Testing
@testable import CoreNetwork

/// Data가 쓰는 `APIEndpoint`가 Moya TargetType으로 그대로 옮겨지는지 확인한다.
struct APIEndpointTests {
    @Test func baseURL은_APIService가_붙이고_경로는_Endpoint를_따른다() {
        let target = EndpointTarget(baseURL: URL(string: "https://api.test")!, endpoint: StubEndpoint())

        #expect(URL(target: target).absoluteString == "https://api.test/endpoint")
    }

    @Test(arguments: [
        (HTTPMethod.get, Moya.Method.get),
        (.post, .post),
        (.put, .put),
        (.patch, .patch),
        (.delete, .delete),
    ])
    func HTTP_메서드를_Moya_메서드로_바꾼다(method: HTTPMethod, expected: Moya.Method) {
        let target = EndpointTarget(baseURL: .stub, endpoint: StubEndpoint(method: method))

        #expect(target.method == expected)
    }

    @Test func 본문이_없으면_requestPlain으로_보낸다() {
        let target = EndpointTarget(baseURL: .stub, endpoint: StubEndpoint())

        guard case .requestPlain = target.task else {
            Issue.record("requestPlain이 아님: \(target.task)")
            return
        }
    }

    @Test func 본문은_JSON으로_인코딩한다() throws {
        let endpoint = StubEndpoint(method: .post, body: StubEndpoint.Body(name: "yg"))
        let target = EndpointTarget(baseURL: .stub, endpoint: endpoint)

        guard case .requestJSONEncodable(let body) = target.task else {
            Issue.record("requestJSONEncodable이 아님: \(target.task)")
            return
        }
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: String]
        #expect(json == ["name": "yg"])
    }

    @Test(arguments: [true, false])
    func 인증_여부를_그대로_넘긴다(requiresAuth: Bool) {
        let target = EndpointTarget(baseURL: .stub, endpoint: StubEndpoint(requiresAuth: requiresAuth))

        #expect(target.requiresAuth == requiresAuth)
    }

    @Test func Endpoint로_요청해도_응답을_디코딩한다() async throws {
        let json = #"{"success": true, "data": {"user_name": "yg"}, "message": null, "code": null}"#
        let service = APIService.stub(.networkResponse(200, Data(json.utf8)))

        let response = try await service.request(StubEndpoint(), responseType: User.self)

        #expect(response == User(userName: "yg"))
    }
}
