import Dependencies
import DependenciesMacros

/// Domain이 Data에 요구하는 포트. 구현(`liveValue`)은 Data 모듈에 있다.
/// Feature는 이 타입을 직접 쓰지 않고 UseCase를 통해서만 접근한다.
@DependencyClient
public struct SampleRepository: Sendable {
    public var fetchSamples: @Sendable () async -> Result<[Sample], DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var sampleRepository: SampleRepository {
        get { self[SampleRepository.self] }
        set { self[SampleRepository.self] = newValue }
    }
}

// 인터페이스 쪽은 TestDependencyKey만 채택한다.
// live 구현은 Data가 `DependencyKey` 채택으로 덧붙이고, 앱 진입점의 `DataModule.bootstrap()`이 등록한다.
extension SampleRepository: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        fetchSamples: { .success([Sample(id: "preview-1"), Sample(id: "preview-2")]) }
    )
}
