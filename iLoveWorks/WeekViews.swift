//
//  WeekViews.swift
//  iLoveWorks
//
//  Week picker + week-by-week history (tasks each day, pay, paid status) for workers and admins.
//

import SwiftUI

struct WeekPickerBar: View {
    let start: String
    let last: String
    let isCurrent: Bool
    let onChange: (String?) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button { onChange(WeekMath.shift(start, by: -1)) } label: {
                Image(systemName: "chevron.left").frame(width: 34, height: 34).background(Theme.surface).clipShape(Circle())
            }
            .accessibilityIdentifier("week-prev")
            VStack(spacing: 1) {
                Text(WeekMath.label(start, last)).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textMain)
                Text(isCurrent ? "THIS WEEK" : "WEEK").font(.system(size: 9, weight: .black)).tracking(1).foregroundStyle(Theme.primary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("week-label")
            Button { onChange(WeekMath.shift(start, by: 1)) } label: {
                Image(systemName: "chevron.right").frame(width: 34, height: 34).background(Theme.surface).clipShape(Circle())
            }
            .disabled(isCurrent)
            .opacity(isCurrent ? 0.3 : 1)
            .accessibilityIdentifier("week-next")
            if !isCurrent {
                Button("This week") { onChange(nil) }
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityIdentifier("week-today")
            }
        }
        .foregroundStyle(Theme.textMain)
    }
}

struct PaidBadge: View {
    let payout: PayoutInfo

    var body: some View {
        Label("Paid \(WeekMath.money(payout.amount))", systemImage: "checkmark.seal.fill")
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.success.opacity(0.12))
            .foregroundStyle(Theme.success)
            .cornerRadius(10)
    }
}

/// Weeks newest first; tap a week to see each day's tasks and pay.
struct WeekHistoryView: View {
    let path: String
    @State private var weeks: [HistoryWeek] = []
    @State private var nextBefore: String?
    @State private var hasMore = false
    @State private var tz: TimeZone = .current
    @State private var loading = false
    @State private var loaded = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 12) {
                    if !loaded {
                        ProgressView().tint(Theme.primary).padding(.top, 40)
                    }
                    if let error {
                        Text(error).font(.system(size: 13)).foregroundStyle(Theme.danger)
                    }
                    ForEach(Array(weeks.enumerated()), id: \.element.id) { i, w in
                        HistoryWeekCard(week: w, tz: tz, startOpen: i == 0)
                    }
                    if hasMore {
                        Button {
                            Task { await load(before: nextBefore) }
                        } label: {
                            HStack {
                                if loading { ProgressView().tint(Theme.primary) }
                                Text("Show older weeks").font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
                        }
                        .foregroundStyle(Theme.primary)
                        .disabled(loading)
                        .accessibilityIdentifier("history-load-older")
                    }
                }
                .padding()
            }
        }
        .task { if !loaded { await load(before: nil) } }
        .refreshable { await load(before: nil) }
    }

    private func load(before: String?) async {
        loading = true
        defer { loading = false; loaded = true }
        let q = before.map { "&before=\($0)" } ?? ""
        do {
            let r: HistoryWeeksResponse = try await APIClient.shared.request("\(path)?weeks=6\(q)")
            weeks = before == nil ? r.weeks : weeks + r.weeks
            nextBefore = r.nextBefore
            hasMore = r.hasMore
            if let name = r.tz, let zone = TimeZone(identifier: name) { tz = zone }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct HistoryWeekCard: View {
    let week: HistoryWeek
    let tz: TimeZone
    @State private var open: Bool

    init(week: HistoryWeek, tz: TimeZone, startOpen: Bool) {
        self.week = week
        self.tz = tz
        _open = State(initialValue: startOpen)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.easeOut(duration: 0.2)) { open.toggle() } } label: {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(WeekMath.label(week.weekStart, week.weekLastDay)).font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.textMain)
                        Text("\(week.tasksCompleted) tasks · \(String(format: "%.1f", week.hours))h").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                        if let p = week.payout { PaidBadge(payout: p) }
                        else if week.earned > 0 { Text("Not paid yet").font(.system(size: 11)).foregroundStyle(Theme.textMuted) }
                    }
                    Spacer()
                    Text(WeekMath.money(week.earned)).font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.primary).monospacedDigit()
                    Image(systemName: "chevron.down").rotationEffect(.degrees(open ? 180 : 0)).foregroundStyle(Theme.textMuted)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("history-week-\(week.weekStart)")
            if open {
                Divider().overlay(Theme.border)
                VStack(spacing: 0) {
                    ForEach(week.days, id: \.date) { d in HistoryDayRow(day: d, tz: tz) }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
        .background(Theme.surface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 1))
    }
}

private struct HistoryDayRow: View {
    let day: HistoryDay
    let tz: TimeZone
    @State private var open = false

    private func time(_ iso: String) -> String {
        let p = ISO8601DateFormatter()
        p.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = p.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        let f = DateFormatter()
        f.timeZone = tz
        f.timeStyle = .short
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { if day.count > 0 { open.toggle() } } label: {
                HStack {
                    Text("\(WeekMath.weekday(day.date)) \(WeekMath.day(day.date))")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 92, alignment: .leading)
                    Text("\(day.count) task\(day.count == 1 ? "" : "s")").font(.system(size: 13))
                    Spacer()
                    Text("\(String(format: "%.1f", day.hours))h").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                    Text(WeekMath.money(day.earned)).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.primary).frame(width: 64, alignment: .trailing)
                }
                .foregroundStyle(day.count == 0 && day.hours == 0 ? Theme.textMuted : Theme.textMain)
            }
            .buttonStyle(.plain)
            if open {
                ForEach(Array(day.tasks.enumerated()), id: \.offset) { _, t in
                    HStack {
                        Text(t.title).lineLimit(1)
                        Text("· \(time(t.completedAt))").foregroundStyle(Theme.textMuted)
                        Spacer()
                        Text(WeekMath.money(t.price))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMain)
                    .padding(.leading, 92)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
