import CoreNetwork
import Foundation

/// 받은 `APIEndpoint`를 기록하고, 정해 둔 JSON이나 에러를 돌려주는 가짜 통신 객체.
final class FakeAPIService: APIServiceProtocol, @unchecked Sendable {
    enum Reply {
        case json(String)
        case failure(any Error)
    }

    private let lock = NSLock()
    private let reply: Reply
    private var _endpoints: [any APIEndpoint] = []

    init(_ reply: Reply) {
        self.reply = reply
    }

    var endpoints: [any APIEndpoint] {
        lock.withLock { _endpoints }
    }

    func request<D: Decodable & Sendable>(
        _ endpoint: some APIEndpoint,
        responseType: D.Type
    ) async throws -> APIResponse<D> {
        let data = try await requestData(endpoint)
        return try JSONDecoder().decode(APIResponse<D>.self, from: data)
    }

    func requestData(_ endpoint: some APIEndpoint) async throws -> Data {
        lock.withLock { _endpoints.append(endpoint) }
        switch reply {
        case let .json(json): return Data(json.utf8)
        case let .failure(error): throw error
        }
    }
}
