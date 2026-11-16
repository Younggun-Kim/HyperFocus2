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

// 기본값(테스트/프리뷰용) 명세
extension SampleRepository: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self()
}
