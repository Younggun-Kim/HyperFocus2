//
//  SessionLogHomeView.swift
//  SessionLog
//
//  Created by 김영건 on 11/24/26.
//

import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct SessionLogHomeView: View {
    let store: StoreOf<SessionLogHomeFeature>

    public init(store: StoreOf<SessionLogHomeFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                summaryCard
                    .overlay {
                        if store.isEmpty {
                            // 빈 그래프 위에 겹쳐 놓는다.
                            Text("Paint your first flow")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(DesignSystemAsset.Colors.systemGray.swiftUIColor)
                                .offset(y: 40)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                if store.isEmpty {
                    emptyTimeline
                } else {
                    timeline
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystemAsset.Colors.bgPrimary.swiftUIColor.ignoresSafeArea())
        .toolbar {
            if #available(iOS 26.0, *) {
                titleToolbarItem
                    .sharedBackgroundVisibility(.hidden)
                settingToolbarItem
                    .sharedBackgroundVisibility(.hidden)
            } else {
                titleToolbarItem
                settingToolbarItem
            }
        }
        .task {
            await store.send(.view(.task)).finish()
        }
        .toast(message: toastBinding)
    }

    // MARK: - 요약

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                caption("Today's Flow")
                Spacer()
                if let todayFocus = store.dashboard?.todayFocusText, !todayFocus.isEmpty, !store.isEmpty {
                    Text(todayFocus)
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                        .foregroundStyle(DesignSystemAsset.Colors.systemBlue.swiftUIColor)
                        .shadow(color: DesignSystemAsset.Colors.systemBlue.swiftUIColor.opacity(0.5), radius: 5)
                } else {
                    Text("Ready")
                        .font(.largeTitle)
                        .foregroundStyle(DesignSystemAsset.Colors.systemGray.swiftUIColor)
                }
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    caption("Total Focus")
                    if let comparison = store.dashboard?.comparisonText, !comparison.isEmpty {
                        Text(comparison)
                            .font(.caption)
                            .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                    }
                }
                Spacer()
                if let weekTotal = store.dashboard?.weekTotalText, !weekTotal.isEmpty {
                    Text(weekTotal)
                        .font(.title.bold())
                        .monospacedDigit()
                        .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                }
            }
            .padding(.bottom, 13)

            WeeklyChartView(chart: store.chart, isEmpty: store.isEmpty)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(DesignSystemAsset.Colors.systemLightGray.swiftUIColor, in: .rect(cornerRadius: 24))
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(DesignSystemAsset.Colors.systemGray.swiftUIColor)
            .padding(.vertical, 6)
    }

    // MARK: - 타임라인

    private var timeline: some View {
        LazyVStack(spacing: 0) {
            ForEach(store.timeline) { row in
                TimelineRowView(row: row)
            }
        }
        .padding(.vertical, 45)
        .padding(.horizontal, 24)
    }

    private var emptyTimeline: some View {
        VStack(spacing: 0) {
            DesignSystemAsset.Assets.arrowDown.swiftUIImage
                .frame(width: 147, height: 147)
                .accessibilityHidden(true)
            Text("Fill this track with your flow.")
                .font(.title)
                .multilineTextAlignment(.center)
                .foregroundStyle(DesignSystemAsset.Colors.systemBlue.swiftUIColor)
                .padding(.top, 35)
                .padding(.bottom, 10)
            Button {
                store.send(.view(.startTapped))
            } label: {
                Text("Start")
                    .font(.title3)
                    .foregroundStyle(DesignSystemAsset.Colors.whiteFix.swiftUIColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(DesignSystemAsset.Colors.systemBlue.swiftUIColor, in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }

    // MARK: - 툴바

    private var titleToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Text("HyperFocus")
                .font(Font.ComingSoon.title)
                .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var settingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.send(.view(.settingTapped))
            } label: {
                DesignSystemAsset.Assets.icGear.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystemAsset.Colors.labelPrimary.swiftUIColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Setting")
        }
    }

    /// 토스트가 시간이 지나 사라지면 nil이 들어온다.
    private var toastBinding: Binding<String?> {
        Binding(
            get: { store.toast },
            set: { if $0 == nil { store.send(.view(.toastDismissed)) } }
        )
    }
}

// MARK: - Preview

import Domain

#Preview("기록 있음") {
    NavigationStack {
        SessionLogHomeView(
            store: Store(initialState: SessionLogHomeFeature.State()) {
                SessionLogHomeFeature()
            } withDependencies: {
                $0.fetchSessionLogDashboardUseCase.execute = { .success(.preview) }
            }
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("기록 없음") {
    NavigationStack {
        SessionLogHomeView(
            store: Store(initialState: SessionLogHomeFeature.State()) {
                SessionLogHomeFeature()
            } withDependencies: {
                $0.fetchSessionLogDashboardUseCase.execute = { .success(SessionLogDashboard(isEmpty: true)) }
            }
        )
    }
    .preferredColorScheme(.dark)
}

private extension SessionLogDashboard {
    static var preview: Self {
        let start = Calendar.current.startOfDay(for: .now).addingTimeInterval(9 * 3600)
        return SessionLogDashboard(
            isEmpty: false,
            todayFocusText: "1h 30m",
            comparisonText: "30m more than yesterday",
            weekTotalText: "4h 10m",
            week: [DailyFocus(day: "-", focusMinutes: 160), DailyFocus(day: "--", focusMinutes: 90)],
            timeline: [
                TimelineEntry(kind: .focus, name: "Reading", startedAt: start, endedAt: start.addingTimeInterval(1500), durationSeconds: 1500, durationMinutes: 25, isNew: true),
                TimelineEntry(kind: .gap, startedAt: start.addingTimeInterval(1500), endedAt: start.addingTimeInterval(2400), durationSeconds: 900, durationMinutes: 15),
                TimelineEntry(kind: .rest, startedAt: start.addingTimeInterval(2400), endedAt: start.addingTimeInterval(2700), durationSeconds: 300, durationMinutes: 5),
            ]
        )
    }
}
