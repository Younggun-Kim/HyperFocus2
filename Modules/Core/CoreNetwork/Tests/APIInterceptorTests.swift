//
//  APIInterceptorTests.swift
//  CoreNetworkTests
//
//  Created by 김영건 on 11/20/26.
//

import Foundation
import Synchronization
import Testing
@testable import CoreNetwork

/// Alamofire `Session`을 거치는 요청을 `MockURLProtocol`로 검증한다.
struct APIInterceptorTests {
    private static let userJSON = Data(#"{"success": true, "data": {"user_name": "yg"}, "message": null, "code": null}"#.utf8)

    /// 4단계: `requiresAuth`에 따라 토큰을 붙이거나, 토큰이 없으면 요청을 보내지 않는다.
    @Suite struct 토큰_주입_테스트 {
        @Test func requiresAuth_요청에_토큰_헤더를_붙인다() async throws {
            let requests = Locked<[URLRequest]>([])
            let host = MockURLProtocol.register { request in
                requests.withLock { $0.append(request) }
                return (.mock(for: request, statusCode: 200), userJSON)
            }
            defer { MockURLProtocol.unregister(host) }
            let service = APIService.mock(storage: InMemoryTokenStorage(.old))

            let response = try await service.request(StubTarget(host: host), responseType: User.self)

            #expect(response.data == User(userName: "yg"))
            #expect(requests.value.map { $0.value(forHTTPHeaderField: "Authorization") } == ["Bearer old-access"])
        }

        @Test func requiresAuth가_false면_토큰이_없어도_헤더_없이_보낸다() async throws {
            let requests = Locked<[URLRequest]>([])
            let host = MockURLProtocol.register { request in
                requests.withLock { $0.append(request) }
                return (.mock(for: request, statusCode: 200), userJSON)
            }
            defer { MockURLProtocol.unregister(host) }
            let service = APIService.mock(storage: InMemoryTokenStorage())

            _ = try await service.request(StubTarget(host: host, requiresAuth: false), responseType: User.self)

            #expect(requests.value.count == 1)
            #expect(requests.value.first?.value(forHTTPHeaderField: "Authorization") == nil)
        }

        @Test func 토큰이_없으면_요청을_보내지_않고_tokenNotFound를_던진다() async throws {
            let requests = Locked<[URLRequest]>([])
            let host = MockURLProtocol.register { request in
                requests.withLock { $0.append(request) }
                return (.mock(for: request, statusCode: 200), userJSON)
            }
            defer { MockURLProtocol.unregister(host) }
            let service = APIService.mock(storage: InMemoryTokenStorage())

            let error = await #expect(throws: APIError.self) {
                try await service.request(StubTarget(host: host), responseType: User.self)
            }

            guard case .tokenNotFound = error else {
                Issue.record("tokenNotFound가 아님: \(String(describing: error))")
                return
            }
            #expect(requests.value.isEmpty)
        }

        @Test func update로_넣은_토큰을_저장하고_다음_요청부터_쓴다() async throws {
            let requests = Locked<[URLRequest]>([])
            let host = MockURLProtocol.register { request in
                requests.withLock { $0.append(request) }
                return (.mock(for: request, statusCode: 200), userJSON)
            }
            defer { MockURLProtocol.unregister(host) }
            let storage = InMemoryTokenStorage()
            let tokenManager = TokenManager.mock(storage: storage)
            let service = APIService(tokenManager: tokenManager, configuration: .mock)

            tokenManager.update(.new)
            _ = try await service.request(StubTarget(host: host), responseType: User.self)

            #expect(storage.load() == .new)
            #expect(requests.value.first?.value(forHTTPHeaderField: "Authorization") == "Bearer new-access")
        }

        /// 3단계에서 남긴 경로: 진행 중인 Alamofire 요청을 취소하면 `AFError.explicitlyCancelled`
        @Test func 진행_중인_요청을_취소하면_cancelled를_던진다() async throws {
            let (started, startedContinuation) = AsyncStream.makeStream(of: Void.self)
            let host = MockURLProtocol.register { request in
                startedContinuation.yield()
                Thread.sleep(forTimeInterval: 0.5)
                return (.mock(for: request, statusCode: 200), userJSON)
            }
            defer { MockURLProtocol.unregister(host) }
            let service = APIService.mock(storage: InMemoryTokenStorage(.old))

            let task = _Concurrency.Task {
                try await service.request(StubTarget(host: host), responseType: User.self)
            }
            for await _ in started { break }
            task.cancel()

            let error = await #expect(throws: APIError.self) {
                try await task.value
            }
            guard case .cancelled = error else {
                Issue.record("cancelled가 아님: \(String(describing: error))")
                return
            }
        }
    }

    /// 5단계: 401이면 갱신 후 재시도하고, 경합 상황에서도 갱신은 필요한 만큼만 한다.
    @Suite struct 토큰_갱신_테스트 {
        @Test func 응답이_401이면_갱신_후_새_토큰으로_재시도한다() async throws {
            let requests = Locked<[URLRequest]>([])
            let host = MockURLProtocol.register(Self.acceptsOnlyNewToken(recordingTo: requests))
            defer { MockURLProtocol.unregister(host) }
            let refreshCount = Locked(0)
            let storage = InMemoryTokenStorage(.old)
            let service = APIService(
                tokenManager: TokenManager(storage: storage) { _ in
                    refreshCount.withLock { $0 += 1 }
                    return .new
                },
                configuration: .mock
            )

            let response = try await service.request(StubTarget(host: host), responseType: User.self)

            #expect(response.data == User(userName: "yg"))
            #expect(refreshCount.value == 1)
            #expect(storage.load() == .new)
            #expect(requests.value.map { $0.value(forHTTPHeaderField: "Authorization") } == ["Bearer old-access", "Bearer new-access"])
        }

        @Test func 동시에_401을_받아도_갱신은_한_번만_한다() async throws {
            let host = MockURLProtocol.register(Self.acceptsOnlyNewToken(recordingTo: Locked([])))
            defer { MockURLProtocol.unregister(host) }
            let refreshCount = Locked(0)
            let service = APIService(
                tokenManager: TokenManager(storage: InMemoryTokenStorage(.old)) { _ in
                    refreshCount.withLock { $0 += 1 }
                    try await _Concurrency.Task.sleep(for: .milliseconds(200))
                    return .new
                },
                configuration: .mock
            )

            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<5 {
                    group.addTask {
                        _ = try await service.request(StubTarget(host: host), responseType: User.self)
                    }
                }
                try await group.waitForAll()
            }

            #expect(refreshCount.value == 1)
        }

        /// 다른 요청이 이미 갱신을 끝낸 뒤 옛 토큰으로 나간 요청의 401이 도착한 상황
        @Test func 옛_토큰으로_나간_요청의_401은_갱신_없이_재시도한다() async throws {
            let refreshCount = Locked(0)
            let tokenManager = TokenManager(storage: InMemoryTokenStorage(.old)) { _ in
                refreshCount.withLock { $0 += 1 }
                return .new
            }
            let requests = Locked<[URLRequest]>([])
            let host = MockURLProtocol.register { request in
                requests.withLock { $0.append(request) }
                if request.value(forHTTPHeaderField: "Authorization") == "Bearer new-access" {
                    return (.mock(for: request, statusCode: 200), userJSON)
                }
                tokenManager.update(.new)
                return (.mock(for: request, statusCode: 401), Data())
            }
            defer { MockURLProtocol.unregister(host) }
            let service = APIService(tokenManager: tokenManager, configuration: .mock)

            _ = try await service.request(StubTarget(host: host), responseType: User.self)

            #expect(refreshCount.value == 0)
            #expect(requests.value.map { $0.value(forHTTPHeaderField: "Authorization") } == ["Bearer old-access", "Bearer new-access"])
        }

        /// 갱신 실패를 세션 만료와 구분하는 일은 6단계에서 한다.
        @Test func 갱신에_실패하면_재시도하지_않고_401을_던진다() async throws {
            let requests = Locked<[URLRequest]>([])
            let host = MockURLProtocol.register { request in
                requests.withLock { $0.append(request) }
                return (.mock(for: request, statusCode: 401), Data())
            }
            defer { MockURLProtocol.unregister(host) }
            let service = APIService(
                tokenManager: TokenManager(storage: InMemoryTokenStorage(.old)) { _ in
                    throw URLError(.notConnectedToInternet)
                },
                configuration: .mock
            )

            let error = await #expect(throws: APIError.self) {
                try await service.request(StubTarget(host: host), responseType: User.self)
            }

            guard case .httpError(let statusCode, _) = error else {
                Issue.record("httpError가 아님: \(String(describing: error))")
                return
            }
            #expect(statusCode == 401)
            #expect(requests.value.count == 1)
        }

        private static func acceptsOnlyNewToken(recordingTo requests: Locked<[URLRequest]>) -> MockURLProtocol.Handler {
            { request in
                requests.withLock { $0.append(request) }
                let statusCode = request.value(forHTTPHeaderField: "Authorization") == "Bearer new-access" ? 200 : 401
                return (.mock(for: request, statusCode: statusCode), userJSON)
            }
        }
    }
}

final class Locked<Value: Sendable>: Sendable {
    private let mutex: Mutex<Value>

    init(_ value: Value) {
        mutex = Mutex(value)
    }

    var value: Value {
        mutex.withLock { $0 }
    }

    func withLock(_ body: (inout Value) -> Void) {
        mutex.withLock { body(&$0) }
    }
}

extension TokenManager {
    static func mock(storage: any TokenStorage) -> TokenManager {
        TokenManager(storage: storage) { _ in
            Issue.record("갱신하면 안 되는 테스트에서 갱신함")
            return .new
        }
    }
}

extension APIService {
    static func mock(storage: any TokenStorage) -> APIService {
        APIService(tokenManager: .mock(storage: storage), configuration: .mock)
    }
}
