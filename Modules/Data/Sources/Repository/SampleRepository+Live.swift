import Dependencies
import Domain

// Domain의 포트에 live 구현을 붙인다.
// Feature는 이 파일을 참조하지 않으므로, 정적 링크에서 빠지지 않도록 `DataModule.bootstrap()`이 직접 참조한다.
extension SampleRepository: @retroactive DependencyKey {
    public static let liveValue = Self(
        fetchSamples: { .success([]) }
    )
}
