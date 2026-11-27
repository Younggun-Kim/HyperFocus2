import DesignSystem
import SwiftUI

struct WeeklyChartView: View {
    let chart: WeeklyChart
    /// 기록이 하나도 없으면 오늘 칸만 점선으로 그린다.
    let isEmpty: Bool

    private let barWidth: CGFloat = 24
    private let maxBarHeight: CGFloat = 51
    private let minBarHeight: CGFloat = 19
    private let barShape = UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(chart.bars) { bar in
                    barView(bar)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxBarHeight, alignment: .bottom)

            Rectangle()
                .fill(DesignSystemAsset.Colors.systemGray.swiftUIColor.opacity(0.5))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(chart.bars) { bar in
                    Text(bar.label)
                        .font(.caption)
                        .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly focus")
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private func barView(_ bar: WeeklyChart.Bar) -> some View {
        if isEmpty, bar.isToday {
            barShape
                .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
                .foregroundStyle(DesignSystemAsset.Colors.systemGray.swiftUIColor)
                .frame(width: barWidth, height: maxBarHeight)
        } else if isEmpty || bar.minutes == 0 {
            Color.clear
                .frame(width: barWidth, height: minBarHeight)
        } else {
            barShape
                .fill(
                    bar.isToday
                        ? DesignSystemAsset.Colors.systemBlue.swiftUIColor
                        : DesignSystemAsset.Colors.systemGray.swiftUIColor
                )
                .frame(width: barWidth, height: max(minBarHeight, bar.heightRatio * maxBarHeight))
        }
    }

    private var accessibilityValue: String {
        guard !isEmpty else { return "No sessions yet" }
        return chart.bars
            .map { "\($0.label) \($0.minutes) min" }
            .joined(separator: ", ")
    }
}

// MARK: - Preview

import Domain

private enum WeeklyChartPreview {
    /// 2026-02-02(월)부터 시작하는 주
    static func chart(_ minutes: [Int], todayIs day: Int) -> WeeklyChart {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 2, day: day))!
        return WeeklyChart(
            week: minutes.enumerated().map { DailyFocus(day: "2026-02-0\($0.offset + 2)", focusMinutes: $0.element) },
            today: today,
            timeZone: calendar.timeZone
        )
    }
}

#Preview("주중 (오늘 = 금, 5일치)") {
    WeeklyChartView(chart: WeeklyChartPreview.chart([60, 0, 120, 30, 5], todayIs: 6), isEmpty: false)
        .padding(24)
        .background(.black)
}

#Preview("오늘 데이터 없음") {
    WeeklyChartView(chart: WeeklyChartPreview.chart([60, 120, 90, 180, 30, 150, 0], todayIs: 8), isEmpty: false)
        .padding(24)
        .background(.black)
}

#Preview("빈 상태 (오늘 = 금)") {
    WeeklyChartView(chart: WeeklyChartPreview.chart([], todayIs: 6), isEmpty: true)
        .padding(24)
        .background(.black)
}
