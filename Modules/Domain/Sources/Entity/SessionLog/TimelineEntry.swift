import Foundation

/// 타임라인의 한 칸. 집중, 휴식, 그 사이의 빈 시간 중 하나다.
public struct TimelineEntry: Sendable, Equatable, Identifiable {
    public enum Kind: Sendable, Equatable {
        case focus
        case rest
        /// 세션과 세션 사이의 빈 시간
        case gap
    }

    /// 빈 시간에는 세션 ID가 없어서 종류와 시작 시각으로 구분한다.
    public struct ID: Sendable, Hashable {
        public let kind: Kind
        public let startedAt: Date
    }

    public var kind: Kind
    /// 사용자가 붙인 세션 이름. 빈 시간에는 없다.
    public var name: String?
    public var startedAt: Date
    public var endedAt: Date
    public var durationSeconds: Int
    public var durationMinutes: Int
    /// 사용자가 아직 보지 못한 세션
    public var isNew: Bool

    public var id: ID { ID(kind: kind, startedAt: startedAt) }

    public init(
        kind: Kind,
        name: String? = nil,
        startedAt: Date,
        endedAt: Date,
        durationSeconds: Int,
        durationMinutes: Int,
        isNew: Bool = false
    ) {
        self.kind = kind
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.durationMinutes = durationMinutes
        self.isNew = isNew
    }
}
