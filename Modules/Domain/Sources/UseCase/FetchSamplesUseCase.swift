import Dependencies
import DependenciesMacros

/// 기록 목록을 불러온다.
@DependencyClient
public struct FetchSamplesUseCase: Sendable {
    public var execute: @Sendable () async throws -> [Sample]
}

extension DependencyValues {
    public var fetchSamplesUseCase: FetchSamplesUseCase {
        get { self[FetchSamplesUseCase.self] }
        set { self[FetchSamplesUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
// 선언과 같은 파일에 두어 Feature가 선언을 참조하면 liveValue도 함께 링크되게 한다.
extension FetchSamplesUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: {
            @Dependency(\.sampleRepository) var sampleRepository
            return try await sampleRepository.fetchSamples()
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
