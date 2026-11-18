public struct Sample: Sendable, Equatable, Identifiable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}
