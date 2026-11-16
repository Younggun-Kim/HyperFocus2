import Dependencies
import DependenciesMacros

@DependencyClient
public struct SampleRepository: Sendable {
    public var getSamples: @Sendable () async throws -> [Sample]
}

// DependencyValues에 등록하여 @Dependency로 꺼내 쓸 수 있게 만듦
extension DependencyValues {
    public var sampleRepository: SampleRepository {
        get { self[SampleRepository.self] }
        set { self[SampleRepository.self] = newValue }
    }
}

// 실제 앱에서 쓰는 구현 + 테스트/프리뷰용 기본값
extension SampleRepository: DependencyKey {
    public static let liveValue = Self(
        getSamples: { [] }
    )
    public static let testValue = Self()
    public static let previewValue = Self()
}
