import Dependencies
import Domain
import Testing

/// UseCase는 지금 Repository에 위임만 한다. 위임이 끊기지 않았는지 확인한다.
struct ObserveSessionExpiredUseCaseTests {
    @Test func 저장소의_만료_이벤트를_그대로_전한다() async {
        let (stream, continuation) = AsyncStream<Void>.makeStream()

        let events = withDependencies {
            $0.authRepository.sessionExpired = { stream }
        } operation: {
            ObserveSessionExpiredUseCase.liveValue.execute()
        }
        continuation.yield()
        continuation.finish()

        var count = 0
        for await _ in events { count += 1 }
        #expect(count == 1)
    }
}
