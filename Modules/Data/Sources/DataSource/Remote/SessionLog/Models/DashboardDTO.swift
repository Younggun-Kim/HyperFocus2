import Domain
import Foundation

/// 화면이 쓰는 필드만 받는다. 서버는 초 단위 집계와 세션 평가도 함께 보낸다.
struct DashboardResponseDTO: Decodable, Sendable, Equatable {
    let isEmpty: Bool
    let todayFocusDisplay: String?
    let diffMessage: String?
    let weekTotalDisplay: String?
    let weeklyData: [DailyFocusDTO]?
    let timeline: [TimelineEntryDTO]?
}

struct DailyFocusDTO: Decodable, Sendable, Equatable {
    let date: String
    let focusMinutes: Int?
}

struct TimelineEntryDTO: Decodable, Sendable, Equatable {
    /// `FOCUS`, `REST`, `GAP`
    let type: String
    let name: String?
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: Int
    let durationMinutes: Int
    let isNew: Bool?
}

extension DashboardResponseDTO {
    func toEntity() -> SessionLogDashboard {
        SessionLogDashboard(
            isEmpty: isEmpty,
            todayFocusText: todayFocusDisplay,
            comparisonText: diffMessage,
            weekTotalText: weekTotalDisplay,
            week: (weeklyData ?? []).map { DailyFocus(day: $0.date, focusMinutes: $0.focusMinutes ?? 0) },
            // 모르는 종류는 버린다. 서버가 종류를 늘려도 화면 전체가 실패하지 않게 한다.
            timeline: (timeline ?? []).compactMap { $0.toEntity() }
        )
    }
}

extension TimelineEntryDTO {
    func toEntity() -> TimelineEntry? {
        let kind: TimelineEntry.Kind
        switch type {
        case "FOCUS": kind = .focus
        case "REST": kind = .rest
        case "GAP": kind = .gap
        default: return nil
        }
        return TimelineEntry(
            kind: kind,
            name: name,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            durationMinutes: durationMinutes,
            isNew: isNew ?? false
        )
    }
}
