import Domain
import Foundation
import Testing
@testable import SessionLog

struct WeeklyChartTests {
    private let utc = TimeZone(identifier: "UTC")!
    /// 2026-02-06(금) 01:00 UTC
    private let friday = Date(timeIntervalSince1970: 1_770_339_600)

    @Test func 항상_월요일부터_7칸을_만들고_모자란_요일은_0으로_채운다() {
        let chart = WeeklyChart(
            week: [DailyFocus(day: "2026-02-02", focusMinutes: 30)],
            today: friday,
            timeZone: utc
        )

        #expect(chart.bars.map(\.label) == ["M", "T", "W", "T", "F", "S", "S"])
        #expect(chart.bars.map(\.minutes) == [30, 0, 0, 0, 0, 0, 0])
    }

    @Test func 서버_날짜에_오늘이_없으면_요일로_오늘_칸을_정한다() {
        let chart = WeeklyChart(week: [], today: friday, timeZone: utc)

        #expect(chart.bars.firstIndex(where: \.isToday) == 4)
        #expect(chart.bars.allSatisfy { $0.heightRatio == 0 })
    }

    @Test func 오늘은_주어진_시간대의_날짜로_정한다() {
        // UTC로는 금요일 01:00이지만 로스앤젤레스는 아직 목요일이다.
        let chart = WeeklyChart(week: [], today: friday, timeZone: TimeZone(identifier: "America/Los_Angeles")!)

        #expect(chart.bars.firstIndex(where: \.isToday) == 3)
    }
}

struct TimelineRowTests {
    private let utc = TimeZone(identifier: "UTC")!
    private let start = Date(timeIntervalSince1970: 1_770_339_600) // 01:00 UTC

    private func entry(_ kind: TimelineEntry.Kind, name: String? = nil, seconds: Int) -> TimelineEntry {
        TimelineEntry(
            kind: kind,
            name: name,
            startedAt: start,
            endedAt: start.addingTimeInterval(TimeInterval(seconds)),
            durationSeconds: seconds,
            durationMinutes: seconds / 60
        )
    }

    @Test func 이름이_없는_세션은_종류에_맞는_기본_이름을_쓴다() {
        let rows = TimelineRow.rows(
            from: [entry(.focus, seconds: 300), entry(.rest, seconds: 300), entry(.focus, name: "Reading", seconds: 300)],
            timeZone: utc
        )

        #expect(rows.map(\.content) == [
            .session(time: "01:00 - 01:05 (5m)", title: "Focus Session", isNew: false),
            .session(time: "01:00 - 01:05 (5m)", title: "Take a Break", isNew: false),
            .session(time: "01:00 - 01:05 (5m)", title: "Reading", isNew: false),
        ])
    }

    @Test func 일_분이_안_되는_빈_시간은_뺀다() {
        let rows = TimelineRow.rows(from: [entry(.gap, seconds: 59), entry(.gap, seconds: 60)], timeZone: utc)

        #expect(rows.map(\.content) == [.gap(minutes: 1)])
    }

    @Test(arguments: [
        (10, "Skill Cooldown Ticking"),
        (11, "Spacing out (It's a talent)"),
        (30, "Spacing out (It's a talent)"),
        (60, "Catching my breath"),
        (61, "Brain Reboot Complete"),
    ])
    func 빈_시간의_문구는_길이에_따라_바뀐다(minutes: Int, title: String) {
        #expect(TimelineRow.gapTitle(minutes: minutes) == title)
    }
}
