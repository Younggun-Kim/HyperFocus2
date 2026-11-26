import Foundation
import Testing
@testable import CoreNetwork

/// `APIEndpoint`에 적은 내용이 실제로 나가는 요청에 그대로 실리는지 확인한다.
/// 서버가 받은 `URLRequest`를 보므로, 요청을 만드는 방식이 바뀌어도 그대로 통과해야 한다.
struct APIEndpointTests {
    private static let userJSON = #"{"success": true, "data": {"user_name": "yg"}}"#

    /// 요청 하나를 보내고 서버가 받은 `URLRequest`를 돌려준다.
    private func sent(
        _ endpoint: StubEndpoint<User>,
        baseURL: (String) -> String = { "https://\($0)" }
    ) async throws -> URLRequest {
        let requests = Locked<[URLRequest]>([])
        let host = MockURLProtocol.register { request in
            requests.withLock { $0.append(request) }
            return (.mock(for: request, statusCode: 200), Data(Self.userJSON.utf8))
        }
        defer { MockURLProtocol.unregister(host) }
        let service = APIService(
            baseURL: URL(string: baseURL(host))!,
            tokenManager: .mock(storage: InMemoryTokenStorage(.old)),
            configuration: .mock
        )

        _ = try await service.request(endpoint).get()

        return try #require(requests.value.first)
    }

    @Test func baseURL은_APIService가_붙이고_경로는_Endpoint를_따른다() async throws {
        let request = try await sent(StubEndpoint(path: "/api/v1/endpoint"))

        #expect(request.url?.path() == "/api/v1/endpoint")
        #expect(request.url?.query() == nil)
    }

    @Test func baseURL에_경로가_있으면_그_뒤에_붙인다() async throws {
        let request = try await sent(StubEndpoint(path: "/endpoint"), baseURL: { "https://\($0)/prefix" })

        #expect(request.url?.path() == "/prefix/endpoint")
    }

    @Test(arguments: [
        (HTTPMethod.get, "GET"),
        (.post, "POST"),
        (.put, "PUT"),
        (.patch, "PATCH"),
        (.delete, "DELETE"),
    ])
    func HTTP_메서드를_그대로_보낸다(method: HTTPMethod, expected: String) async throws {
        let request = try await sent(StubEndpoint(method: method))

        #expect(request.httpMethod == expected)
    }

    @Test(arguments: [HTTPMethod.get, .post])
    func 본문이_없으면_본문_없이_보낸다(method: HTTPMethod) async throws {
        let request = try await sent(StubEndpoint(method: method))

        #expect(request.bodyData ?? Data() == Data())
    }

    /// 서버는 camelCase 키를 받는다. 키를 snake_case로 바꾸지 않는다.
    @Test func 본문은_키를_바꾸지_않고_JSON으로_인코딩한다() async throws {
        let request = try await sent(StubEndpoint(method: .post, body: StubEndpoint<User>.Body()))

        let body = try #require(request.bodyData)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(json == ["name": "yg", "userName": "yg"])
    }

    @Test(arguments: [
        StubEndpoint<User>(method: .get),
        StubEndpoint<User>(method: .post, body: StubEndpoint<User>.Body()),
    ])
    func 본문이_있든_없든_JSON_헤더를_붙인다(endpoint: StubEndpoint<User>) async throws {
        let request = try await sent(endpoint)

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
