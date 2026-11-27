import Domain
import Foundation

/// 타임라인 한 줄에 보여 줄 값.
struct TimelineRow: Equatable, Identifiable {
    enum Content: Equatable {
        /// 집중 또는 휴식. `time`은 `15:55 - 16:00 (5m)` 형식이다.
        case session(time: String, title: String, isNew: Bool)
        case gap(minutes: Int)
    }

    let id: TimelineEntry.ID
    let content: Content
}

extension TimelineRow {
    /// 1분이 안 되는 빈 시간은 줄로 만들지 않는다.
    static func rows(from timeline: [TimelineEntry], timeZone: TimeZone) -> [TimelineRow] {
        timeline.compactMap { entry in
            switch entry.kind {
            case .focus:
                TimelineRow(id: entry.id, content: entry.session(fallbackTitle: "Focus Session", timeZone: timeZone))
            case .rest:
                TimelineRow(id: entry.id, content: entry.session(fallbackTitle: "Take a Break", timeZone: timeZone))
            case .gap:
                entry.durationSeconds >= 60
                    ? TimelineRow(id: entry.id, content: .gap(minutes: entry.durationMinutes))
                    : nil
            }
        }
    }

    /// 빈 시간의 길이에 따라 바뀌는 문구.
    static func gapTitle(minutes: Int) -> String {
        switch minutes {
        case ...10: "Skill Cooldown Ticking"
        case ...30: "Spacing out (It's a talent)"
        case ...60: "Catching my breath"
        default: "Brain Reboot Complete"
        }
    }
}

private extension TimelineEntry {
    func session(fallbackTitle: String, timeZone: TimeZone) -> TimelineRow.Content {
        // 기기의 12/24시간 설정과 상관없이 24시간으로 적는다.
        let clock = Date.VerbatimFormatStyle(
            format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
            timeZone: timeZone,
            calendar: Calendar(identifier: .gregorian)
        )
        return .session(
            time: "\(startedAt.formatted(clock)) - \(endedAt.formatted(clock)) (\(durationMinutes)m)",
            title: name ?? fallbackTitle,
            isNew: isNew
        )
    }
}
