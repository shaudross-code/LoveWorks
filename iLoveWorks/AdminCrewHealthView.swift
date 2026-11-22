//
//  AdminCrewHealthView.swift
//  iLoveWorks
//
//  Admin: every worker's calories and weight for a week, sortable, with a CSV to share.
//

import SwiftUI

struct AdminCrewHealthView: View {
    enum SortKey: String, CaseIterable, Identifiable {
        case active = "Active (week)", activeAvg = "Avg active/day", total = "Total (week)", weight = "Weight", change = "Weight change", name = "Name"
        var id: String { rawValue }
    }

    @State private var week: String?
    @State private var data: CrewHealthWeek?
    @State private var sort: SortKey = .active
    @State private var ascending = false
    @State private var error: String?

    private static func lb(_ kg: Double) -> String { String(format: "%.1f", kg * 2.20462) }
    private static func kcal(_ v: Double?) -> String { v.map { Int($0.rounded()).formatted() } ?? "—" }

    private func value(_ r: CrewHealthRow) -> Double? {
        guard r.shared else { return nil }
        switch sort {
        case .active: return r.activeTotal
        case .activeAvg: return r.activeAvg
        case .total: return r.totalTotal
        case .weight: return r.latestWeightKg
        case .change: return r.weightChangeKg
        case .name: return nil
        }
    }

    private var rows: [CrewHealthRow] {
        let all = data?.rows ?? []
        if sort == .name {
            let byName = all.sorted { $0.worker.name.localizedCaseInsensitiveCompare($1.worker.name) == .orderedAscending }
            return ascending ? byName : byName.reversed()
        }
        return all.sorted { a, b in
            switch (value(a), value(b)) {
            case let (x?, y?): return ascending ? x < y : x > y
            case (.some, nil): return true
            case (nil, .some): return false
            default: return a.worker.name < b.worker.name
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let d = data {
                        WeekPickerBar(start: d.weekStart, last: d.weekLastDay, isCurrent: d.isCurrent) { week = $0 }
                        HStack {
                            Menu {
                                Picker("Sort by", selection: $sort) {
                                    ForEach(SortKey.allCases) { Text($0.rawValue).tag($0) }
                                }
                            } label: {
                                Label("Sort: \(sort.rawValue)", systemImage: "arrow.up.arrow.down")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .accessibilityIdentifier("health-sort")
                            Button { ascending.toggle() } label: {
                                Image(systemName: ascending ? "arrow.up" : "arrow.down")
                            }
                            .accessibilityIdentifier("health-sort-direction")
                            Spacer()
                            if let file = csvFile(d) {
                                ShareLink(item: file) { Label("CSV", systemImage: "square.and.arrow.up").font(.system(size: 13, weight: .semibold)) }
                                    .accessibilityIdentifier("health-csv")
                            }
                        }
                        .foregroundStyle(Theme.primary)
                        ForEach(rows) { r in CrewHealthCard(row: r) }
                        Text("Averages count only days with calories. Change compares the last weigh-in this week with the one before it.")
                            .font(.system(size: 11)).foregroundStyle(Theme.textMuted)
                    } else if let error {
                        Text(error).font(.system(size: 13)).foregroundStyle(Theme.danger)
                    } else {
                        ProgressView().tint(Theme.primary).frame(maxWidth: .infinity).padding(.top, 40)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Crew Health")
        .inlineNavigationTitle()
        .task(id: week) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            data = try await APIClient.shared.request("/admin/health/crew\(week.map { "?week=\($0)" } ?? "")")
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func csvFile(_ d: CrewHealthWeek) -> URL? {
        func cell(_ s: String) -> String { s.contains(",") || s.contains("\"") ? "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\"" : s }
        var lines = ["Worker,Email,Shared,Active kcal (week),Avg active kcal/day,Total kcal (week),Avg total kcal/day,Days with data,Latest weight (lb),Weight date,Weight change (lb)"]
        for r in d.rows {
            let cols: [String] = r.shared
                ? [r.worker.name, r.worker.email, "yes", Self.kcal(r.activeTotal), Self.kcal(r.activeAvg), Self.kcal(r.totalTotal), Self.kcal(r.totalAvg),
                   "\(r.daysWithData ?? 0)", r.latestWeightKg.map(Self.lb) ?? "", r.latestWeightDate ?? "", r.weightChangeKg.map(Self.lb) ?? ""]
                : [r.worker.name, r.worker.email, "not shared", "", "", "", "", "", "", "", ""]
            lines.append(cols.map { cell($0.replacingOccurrences(of: "—", with: "").replacingOccurrences(of: ",", with: "")) }.joined(separator: ","))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("crew-health-\(d.weekStart).csv")
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

private struct CrewHealthCard: View {
    let row: CrewHealthRow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(row.worker.name).font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.textMain)
                Spacer()
                if !row.shared {
                    Label("Not shared", systemImage: "eye.slash").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                } else if let kg = row.latestWeightKg {
                    HStack(spacing: 4) {
                        Text("\(String(format: "%.1f", kg * 2.20462)) lb").font(.system(size: 14, weight: .bold)).foregroundStyle(.cyan)
                        if row.weightSource == "scale_bluetooth" { Image(systemName: "dot.radiowaves.left.and.right").font(.system(size: 10)).foregroundStyle(.cyan) }
                        if let c = row.weightChangeKg {
                            Text("\(c < 0 ? "−" : "+")\(String(format: "%.1f", abs(c) * 2.20462))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(c < 0 ? Theme.success : .orange)
                        }
                    }
                }
            }
            if row.shared, let days = row.days {
                let peak = max(1, days.compactMap(\.activeKcal).max() ?? 1)
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(days, id: \.date) { d in
                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.orange.opacity((d.activeKcal ?? 0) > 0 ? 0.85 : 0.15))
                                .frame(height: max(4, CGFloat((d.activeKcal ?? 0) / peak) * 36))
                            Text(String(WeekMath.weekday(d.date).prefix(1))).font(.system(size: 9)).foregroundStyle(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 50)
                HStack {
                    stat("ACTIVE", row.activeTotal, row.activeAvg)
                    stat("TOTAL", row.totalTotal, row.totalAvg)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 1))
        .accessibilityIdentifier("health-row-\(row.worker.id)")
    }

    private func stat(_ label: String, _ total: Double?, _ avg: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 9, weight: .black)).tracking(1).foregroundStyle(Theme.textMuted)
            Text("\(Int((total ?? 0).rounded()).formatted()) kcal").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textMain)
            Text("avg \(avg.map { Int($0.rounded()).formatted() } ?? "—")/day").font(.system(size: 11)).foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
