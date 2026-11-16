import Dependencies
import Domain

extension SampleRepository: @retroactive DependencyKey {
    public static let liveValue = Self(
        getSamples: { [] }
    )
}
