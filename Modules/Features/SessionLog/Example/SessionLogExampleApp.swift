import ComposableArchitecture
import Domain
import SwiftUI
import SessionLog

@main
struct SessionLogExampleApp: App {
    init() {
        // 예제 앱은 Data를 링크하지 않으므로 Repository의 live 구현이 없다.
        // Repository 포트에 mock을 넣으면 UseCase는 실제 로직(liveValue)대로 동작한다.
        prepareDependencies {
            $0.sessionLogRepository.fetchDashboard = {
                try? await Task.sleep(for: .seconds(1))
                // 실행 인자에 `-empty`를 넣으면 기록이 없는 화면을 본다.
                return .success(ProcessInfo.processInfo.arguments.contains("-empty") ? .init(isEmpty: true) : .example)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            // 툴바를 보이게 하려고 감싼다. Setting으로의 push는 App에서만 일어난다.
            NavigationStack {
                SessionLogHomeView(
                    store: Store(initialState: SessionLogHomeFeature.State()) {
                        SessionLogHomeFeature()
                    }
                )
            }
            // 앱은 항상 다크 모드로 보여 준다.
            .preferredColorScheme(.dark)
        }
    }
}

private extension SessionLogDashboard {
    /// 이번 주 월요일부터 오늘까지의 기록.
    static var example: Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: .now)
        let monday = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let dayCount = (calendar.dateComponents([.day], from: monday, to: today).day ?? 0) + 1
        let minutes = [60, 0, 120, 30, 45, 90, 25]

        let week = (0..<dayCount).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: monday) ?? monday
            let parts = calendar.dateComponents([.year, .month, .day], from: date)
            return DailyFocus(
                day: String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0),
                focusMinutes: minutes[offset % minutes.count]
            )
        }

        let start = today.addingTimeInterval(9 * 3600)
        func entry(_ kind: TimelineEntry.Kind, _ name: String? = nil, from: Int, minutes: Int, isNew: Bool = false) -> TimelineEntry {
            TimelineEntry(
                kind: kind,
                name: name,
                startedAt: start.addingTimeInterval(TimeInterval(from * 60)),
                endedAt: start.addingTimeInterval(TimeInterval((from + minutes) * 60)),
                durationSeconds: minutes * 60,
                durationMinutes: minutes,
                isNew: isNew
            )
        }

        return SessionLogDashboard(
            isEmpty: false,
            todayFocusText: "1h 15m",
            comparisonText: "30m more than yesterday",
            weekTotalText: "5h 45m",
            week: week,
            timeline: [
                entry(.focus, "Reading a very long book title that wraps onto the next line", from: 0, minutes: 25, isNew: true),
                entry(.gap, from: 25, minutes: 5),
                entry(.rest, from: 30, minutes: 5),
                entry(.gap, from: 35, minutes: 25),
                entry(.focus, from: 60, minutes: 50),
            ]
        )
    }
}
