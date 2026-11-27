import Domain
import Foundation

/// 주간 막대 그래프가 그리는 값. 항상 월요일부터 일요일까지 7칸이다.
struct WeeklyChart: Equatable {
    struct Bar: Equatable, Identifiable {
        /// 월요일이 0인 요일 순서
        let id: Int
        let label: String
        let minutes: Int
        let isToday: Bool
        /// 가장 긴 날을 1로 본 비율. 기록이 없는 주는 모두 0이다.
        let heightRatio: Double
    }

    private static let labels = ["M", "T", "W", "T", "F", "S", "S"]

    let bars: [Bar]

    /// 오늘이 언제인지 알기 전에 쓰는 빈 그래프.
    static let placeholder = WeeklyChart(minutes: [], todayIndex: nil)

    /// - Parameters:
    ///   - week: 월요일부터의 날짜별 값. 7개보다 적으면 남은 요일은 0으로 채운다.
    ///   - timeZone: 오늘 날짜를 정하는 시간대
    init(week: [DailyFocus], today: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date = calendar.dateComponents([.year, .month, .day, .weekday], from: today)
        let todayString = String(format: "%04d-%02d-%02d", date.year ?? 0, date.month ?? 0, date.day ?? 0)

        // 서버가 준 날짜와 맞춰 보고, 없으면 요일로 정한다. weekday는 일=1 ... 토=7이다.
        let todayIndex = week.prefix(Self.labels.count).firstIndex { $0.day == todayString }
            ?? ((date.weekday ?? 2) + 5) % 7

        self.init(minutes: week.map(\.focusMinutes), todayIndex: todayIndex)
    }

    private init(minutes: [Int], todayIndex: Int?) {
        let filled = Self.labels.indices.map { $0 < minutes.count ? max(minutes[$0], 0) : 0 }
        let longest = filled.max() ?? 0
        bars = Self.labels.indices.map { index in
            Bar(
                id: index,
                label: Self.labels[index],
                minutes: filled[index],
                isToday: index == todayIndex,
                heightRatio: longest > 0 ? Double(filled[index]) / Double(longest) : 0
            )
        }
    }
}
