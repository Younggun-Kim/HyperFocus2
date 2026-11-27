/// 기록 탭 첫 화면에 보여 주는 요약. 집계는 서버가 한다.
///
/// 계정마다 하나뿐인 값이라 `Identifiable`을 채택하지 않는다.
public struct SessionLogDashboard: Sendable, Equatable {
    /// 기록이 하나도 없다.
    public var isEmpty: Bool
    /// 오늘 집중한 시간. 서버가 표시용으로 만든 문자열이다.
    public var todayFocusText: String?
    /// 어제와 비교한 문장. 서버가 표시용으로 만든 문자열이다.
    public var comparisonText: String?
    /// 이번 주에 집중한 시간. 서버가 표시용으로 만든 문자열이다.
    public var weekTotalText: String?
    /// 이번 주 월요일부터의 날짜별 집중 시간. 주중에는 오늘까지만 온다.
    public var week: [DailyFocus]
    /// 오늘 한 일을 시간 순서로 늘어놓은 것.
    public var timeline: [TimelineEntry]

    public init(
        isEmpty: Bool,
        todayFocusText: String? = nil,
        comparisonText: String? = nil,
        weekTotalText: String? = nil,
        week: [DailyFocus] = [],
        timeline: [TimelineEntry] = []
    ) {
        self.isEmpty = isEmpty
        self.todayFocusText = todayFocusText
        self.comparisonText = comparisonText
        self.weekTotalText = weekTotalText
        self.week = week
        self.timeline = timeline
    }
}

/// 하루 동안 집중한 시간.
public struct DailyFocus: Sendable, Equatable, Identifiable {
    /// `yyyy-MM-dd` 형식의 날짜.
    public var day: String
    public var focusMinutes: Int

    public var id: String { day }

    public init(day: String, focusMinutes: Int) {
        self.day = day
        self.focusMinutes = focusMinutes
    }
}
