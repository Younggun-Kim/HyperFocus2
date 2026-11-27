import Foundation
import Synchronization

/// 세션 만료를 구독자 모두에게 알린다.
///
/// `AsyncStream` 하나는 구독자 하나에게만 값을 주므로, 구독할 때마다 스트림을 새로 만들어 따로 보낸다.
/// 구독이 끝나면(Task 취소 등) 목록에서 빠진다.
final class SessionExpiryBroadcaster: Sendable {
    private let continuations = Mutex<[UUID: AsyncStream<Void>.Continuation]>([:])

    /// 지금부터 생기는 만료를 받는 스트림. 받기 전에 여러 번 만료돼도 하나만 남긴다.
    func stream() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        continuations.withLock { $0[id] = continuation }
        continuation.onTermination = { [weak self] _ in
            self?.continuations.withLock { _ = $0.removeValue(forKey: id) }
        }
        return stream
    }

    func notify() {
        let subscribers = continuations.withLock { Array($0.values) }
        for continuation in subscribers {
            continuation.yield()
        }
    }
}
