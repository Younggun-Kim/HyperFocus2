import CoreNetwork
import Foundation

/// 받은 `APIEndpoint`를 기록하고, 정해 둔 JSON이나 에러를 돌려주는 가짜 통신 객체.
/// 응답을 여러 개 주면 요청마다 차례로 돌려주고, 마지막 응답은 계속 돌려준다.
/// 디코딩과 봉투 열기는 `APIServiceProtocol`의 extension이 실제와 똑같이 한다.
final class FakeAPIService: APIServiceProtocol, @unchecked Sendable {
    enum Reply {
        case json(String)
        case failure(APIError)
    }

    private let lock = NSLock()
    private var replies: [Reply]
    private var _endpoints: [any APIEndpoint] = []

    init(_ replies: [Reply]) {
        precondition(!replies.isEmpty, "응답을 하나 이상 정한다")
        self.replies = replies
    }

    convenience init(_ replies: Reply...) {
        self.init(replies)
    }

    var endpoints: [any APIEndpoint] {
        lock.withLock { _endpoints }
    }

    func requestData(_ endpoint: some APIEndpoint) async -> Result<Data, APIError> {
        let reply = lock.withLock {
            _endpoints.append(endpoint)
            return replies.count > 1 ? replies.removeFirst() : replies[0]
        }
        switch reply {
        case let .json(json): return .success(Data(json.utf8))
        case let .failure(error): return .failure(error)
        }
    }
}
