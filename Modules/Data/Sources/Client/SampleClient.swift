import Dependencies
import DependenciesMacros

@DependencyClient
public struct SampleClient: Sendable {
    public var getSamples: @Sendable () async throws -> [Sample]
}

// DependencyValues에 등록하여 @Dependency로 꺼내 쓸 수 있게 만듦
extension DependencyValues {
    public var sampleClient: SampleClient {
        get { self[SampleClient.self] }
        set { self[SampleClient.self] = newValue }
    }
}

// 실제 앱에서 쓰는 구현 + 테스트/프리뷰용 기본값
// 선언과 같은 파일에 두어야 Feature가 선언을 참조할 때 liveValue도 함께 링크된다.
extension SampleClient: DependencyKey {
    public static let liveValue = Self(
        getSamples: { [] }
    )
    public static let testValue = Self()
    public static let previewValue = Self(
        getSamples: { [Sample(id: "preview-1"), Sample(id: "preview-2")] }
    )
}
