import Foundation
import Synchronization

/// 지금 값을 들고 있다가, 구독하면 지금 값을 먼저 보내고 바뀔 때마다 모든 구독자에게 보낸다.
///
/// `AsyncStream` 하나는 구독자 하나에게만 값을 주므로, 구독할 때마다 스트림을 새로 만든다.
/// 구독이 끝나면(Task 취소 등) 목록에서 빠진다.
final class CurrentValueBroadcaster<Value: Sendable & Equatable>: Sendable {
    private struct State {
        var value: Value
        var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]
    }

    private let state: Mutex<State>

    init(_ value: Value) {
        state = Mutex(State(value: value))
    }

    var value: Value {
        state.withLock { $0.value }
    }

    /// 늦게 읽는 구독자에게는 가장 최근 값 하나만 남긴다.
    func stream() -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream<Value>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        // 지금 값을 보내는 것과 목록에 넣는 것을 한 번에 해야 그 사이의 변경을 놓치지 않는다.
        state.withLock {
            continuation.yield($0.value)
            $0.continuations[id] = continuation
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLock { _ = $0.continuations.removeValue(forKey: id) }
        }
        return stream
    }

    /// 같은 값이면 보내지 않는다.
    func send(_ value: Value) {
        state.withLock {
            guard $0.value != value else { return }
            $0.value = value
            // 잠근 채로 보내야 두 변경이 엇갈린 순서로 도착하지 않는다. `yield`는 기다리지 않는다.
            for continuation in $0.continuations.values {
                continuation.yield(value)
            }
        }
    }
}
