import DesignSystem
import SwiftUI

struct TimelineRowView: View {
    let row: TimelineRow

    var body: some View {
        switch row.content {
        case let .session(time, title, isNew):
            session(time: time, title: title, isNew: isNew)
        case let .gap(minutes):
            gap(minutes: minutes)
        }
    }

    private func session(time: String, title: String, isNew: Bool) -> some View {
        HStack(alignment: .top, spacing: 20) {
            marker(DesignSystemAsset.Colors.systemBlue.swiftUIColor)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(time)
                        .font(.body)
                        .monospacedDigit()
                        .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                    Spacer()
                    if isNew {
                        newBadge
                    }
                }
                Text(title)
                    .font(.title)
                    .foregroundStyle(DesignSystemAsset.Colors.systemBlue.swiftUIColor)
                    .lineLimit(3)
            }
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func gap(minutes: Int) -> some View {
        // 10분이 넘는 빈 시간은 길이도 함께 적고 칸을 키운다.
        let isLong = minutes > 10
        return HStack(spacing: 20) {
            marker(DesignSystemAsset.Colors.systemLightGray.swiftUIColor)
            VStack(alignment: .leading, spacing: 6) {
                Text(TimelineRow.gapTitle(minutes: minutes))
                if isLong {
                    Text("+\(minutes)m")
                }
            }
            .font(.caption)
            .foregroundStyle(DesignSystemAsset.Colors.systemGray.swiftUIColor)
        }
        .frame(maxWidth: .infinity, minHeight: isLong ? 90 : 32, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func marker(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 8)
    }

    private var newBadge: some View {
        Text("New")
            .font(.caption)
            .foregroundStyle(DesignSystemAsset.Colors.whiteFix.swiftUIColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(DesignSystemAsset.Colors.systemGray.swiftUIColor, in: .capsule)
    }
}
