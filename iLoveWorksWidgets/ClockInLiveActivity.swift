//
//  ClockInLiveActivity.swift
//  iLoveWorksWidgets
//
//  Live clock-in timer on the Lock Screen and Dynamic Island. The timer text is drawn
//  by iOS itself (Text(date, style: .timer)), so it keeps ticking with the app closed.
//

import ActivityKit
import SwiftUI
import WidgetKit

private let gold = Color(red: 0.98, green: 0.80, blue: 0.08)
private let breakBlue = Color(red: 0.38, green: 0.65, blue: 1.0)

private func accent(_ state: ClockInAttributes.ContentState) -> Color { state.onBreak ? breakBlue : gold }
private func icon(_ state: ClockInAttributes.ContentState) -> String { state.onBreak ? "cup.and.saucer.fill" : "clock.fill" }

struct ClockInLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClockInAttributes.self) { context in
            ClockInLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(gold)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.onBreak ? "On break" : "On the clock", systemImage: icon(context.state))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accent(context.state))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startDate, style: .timer)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 110, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.activityLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: icon(context.state)).foregroundStyle(accent(context.state))
            } compactTrailing: {
                Text(context.attributes.startDate, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 56)
                    .foregroundStyle(accent(context.state))
            } minimal: {
                Image(systemName: icon(context.state)).foregroundStyle(accent(context.state))
            }
        }
    }
}

struct ClockInLockScreenView: View {
    let context: ActivityViewContext<ClockInAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(accent(context.state).opacity(0.18)).frame(width: 44, height: 44)
                Image(systemName: icon(context.state)).foregroundStyle(accent(context.state))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.onBreak ? "ON BREAK" : "ON THE CLOCK")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(accent(context.state))
                Text(context.state.activityLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                if !context.attributes.workerName.isEmpty {
                    Text(context.attributes.workerName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
            Text(context.attributes.startDate, style: .timer)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 130, alignment: .trailing)
        }
        .padding(16)
    }
}
