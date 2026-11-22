//
//  AdminPayrollWeekView.swift
//  iLoveWorks
//
//  Admin payroll: pick a week, see each worker's tasks per day and pay, mark paid / undo,
//  open the Google Sheet record, plus all-time earned / paid / owed.
//

import SwiftUI

struct AdminPayrollView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.openURL) private var openURL
    @State private var week: String?
    @State private var data: PayrollWeek?
    @State private var sheet: PayrollSheetStatus?
    @State private var busy = false
    @State private var message: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let d = data {
                        WeekPickerBar(start: d.weekStart, last: d.weekLastDay, isCurrent: d.isCurrent) { week = $0 }
                        if d.isCurrent {
                            Text("This week isn't over yet. Totals keep growing until Sunday night.")
                                .font(.system(size: 12)).foregroundStyle(.orange)
                        }
                        HStack(spacing: 10) {
                            AdminStatCard(label: "EARNED", value: WeekMath.money(d.totals.earned), icon: "dollarsign.circle.fill")
                            AdminStatCard(label: "PAID", value: WeekMath.money(d.totals.paid), icon: "checkmark.seal.fill", accent: Theme.success)
                        }
                        AdminStatCard(label: "NOT PAID YET", value: WeekMath.money(d.totals.unpaid), icon: "hourglass", accent: Theme.lovePink)
                        sheetBar
                        let unpaid = d.rows.filter { $0.payout == nil && $0.earned > 0 }.count
                        Button { Task { await markPaid(nil) } } label: {
                            Label(unpaid > 0 ? "Mark all paid (\(unpaid))" : "Everyone is paid", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Theme.primary)
                                .foregroundStyle(.black)
                                .cornerRadius(100)
                        }
                        .disabled(busy || unpaid == 0 || d.isFuture)
                        .opacity(unpaid == 0 ? 0.5 : 1)
                        .accessibilityIdentifier("payroll-mark-all-paid")
                        if let message {
                            Text(message).font(.system(size: 12)).foregroundStyle(Theme.danger)
                        }
                        ForEach(d.rows) { r in
                            PayrollWeekRowView(row: r, busy: busy, canPay: !d.isFuture,
                                               onPay: { Task { await markPaid([r.worker.id]) } },
                                               onUndo: { Task { await undo(r.worker.id) } })
                        }
                    } else {
                        ProgressView().tint(Theme.primary).frame(maxWidth: .infinity).padding(.top, 40)
                    }
                    allTime
                }
                .padding()
            }
        }
        .navigationTitle("Payroll")
        .inlineNavigationTitle()
        .task(id: week) { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder private var sheetBar: some View {
        if let s = sheet, s.configured {
            HStack(spacing: 10) {
                Image(systemName: "tablecells.fill").foregroundStyle(Theme.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Google Sheet").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.textMain)
                    Text(s.error.map { "Sync problem: \($0)" } ?? (s.url == nil ? "Created with the first paid week" : "\(s.synced) paid week\(s.synced == 1 ? "" : "s") copied\(s.pending > 0 ? " · \(s.pending) waiting" : "")"))
                        .font(.system(size: 11)).foregroundStyle(s.error == nil ? Theme.textMuted : Theme.danger).lineLimit(2)
                }
                Spacer()
                if s.pending > 0 || s.error != nil {
                    Button("Sync") { Task { await syncSheet() } }
                        .font(.system(size: 12, weight: .bold)).disabled(busy)
                        .accessibilityIdentifier("payroll-sheet-sync")
                }
                if let link = s.url, let url = URL(string: link) {
                    Button("Open") { openURL(url) }
                        .font(.system(size: 12, weight: .bold))
                        .accessibilityIdentifier("payroll-sheet-open")
                }
            }
            .padding(12)
            .background(Theme.surface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
        }
    }

    private var allTime: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ALL TIME").font(.system(size: 11, weight: .black)).tracking(1.5).foregroundStyle(Theme.textMuted).padding(.top, 10)
            HStack(spacing: 10) {
                AdminStatCard(label: "EARNED", value: WeekMath.money(viewModel.payroll.reduce(0) { $0 + $1.tasksEarnings }), icon: "sum")
                AdminStatCard(label: "STILL OWED", value: WeekMath.money(viewModel.payroll.reduce(0) { $0 + ($1.owed ?? $1.tasksEarnings) }), icon: "hourglass", accent: Theme.lovePink)
            }
            ForEach(viewModel.payroll) { row in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.worker.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textMain)
                        Text("\(row.tasksCompleted) tasks · \(String(format: "%.1f", row.totalHours))h").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(WeekMath.money(row.tasksEarnings)).font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.success)
                        Text("paid \(WeekMath.money(row.paidTotal ?? 0)) · owed \(WeekMath.money(row.owed ?? row.tasksEarnings))")
                            .font(.system(size: 11)).foregroundStyle(Theme.textMuted)
                    }
                }
                .padding(14)
                .background(Theme.surface)
                .cornerRadius(14)
            }
        }
    }

    private func load() async {
        let q = week.map { "?week=\($0)" } ?? ""
        do {
            data = try await APIClient.shared.request("/payroll/week\(q)")
            message = nil
        } catch {
            message = error.localizedDescription
        }
        sheet = try? await APIClient.shared.request("/payroll/sheet")
        await viewModel.refreshDashboard()
    }

    /// The sheet copy runs in the background on the server; check again shortly.
    private func refreshSheetSoon() {
        Task {
            try? await Task.sleep(for: .seconds(5))
            sheet = try? await APIClient.shared.request("/payroll/sheet")
        }
    }

    private func markPaid(_ ids: [String]?) async {
        guard let ws = data?.weekStart else { return }
        busy = true
        defer { busy = false }
        do {
            let _: MarkPaidResponse = try await APIClient.shared.send("/payroll/week/\(ws)/paid", json: MarkPaidRequest(workerIds: ids))
            await load()
            refreshSheetSoon()
        } catch {
            message = error.localizedDescription
        }
    }

    private func undo(_ workerId: String) async {
        guard let ws = data?.weekStart else { return }
        busy = true
        defer { busy = false }
        do {
            let _: EmptyResponse = try await APIClient.shared.request("/payroll/week/\(ws)/paid/\(workerId)", method: "DELETE")
            await load()
            refreshSheetSoon()
        } catch {
            message = error.localizedDescription
        }
    }

    private func syncSheet() async {
        busy = true
        defer { busy = false }
        do {
            let _: SheetSyncResponse = try await APIClient.shared.request("/payroll/sheet/sync", method: "POST")
        } catch {
            message = error.localizedDescription
        }
        sheet = try? await APIClient.shared.request("/payroll/sheet")
    }
}

private struct PayrollWeekRowView: View {
    let row: PayrollWeekRow
    let busy: Bool
    let canPay: Bool
    let onPay: () -> Void
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.worker.name).font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.textMain)
                    Text("\(row.tasksCompleted) tasks · \(String(format: "%.1f", row.hours))h").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                }
                Spacer()
                Text(WeekMath.money(row.earned)).font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.primary).monospacedDigit()
            }
            HStack(spacing: 4) {
                ForEach(row.days, id: \.date) { d in
                    VStack(spacing: 2) {
                        Text(String(WeekMath.weekday(d.date).prefix(2)).uppercased()).font(.system(size: 8, weight: .black)).foregroundStyle(Theme.textMuted)
                        Text("\(d.count)").font(.system(size: 12, weight: .bold)).foregroundStyle(d.count > 0 ? Theme.primary : Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(d.count > 0 ? Theme.primary.opacity(0.1) : Theme.secondary.opacity(0.4))
                    .cornerRadius(8)
                }
            }
            HStack {
                if let p = row.payout {
                    PaidBadge(payout: p)
                    if row.changedSincePaid {
                        Text("Now \(WeekMath.money(row.earned))").font(.system(size: 11)).foregroundStyle(.orange)
                    }
                    Spacer()
                    Button("Undo", action: onUndo)
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textMuted).disabled(busy)
                        .accessibilityIdentifier("payroll-undo-\(row.worker.id)")
                } else if row.earned <= 0 {
                    Text("Nothing to pay").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                    Spacer()
                } else {
                    Spacer()
                    Button(action: onPay) {
                        Label("Mark paid", systemImage: "checkmark.seal")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .overlay(Capsule().stroke(Theme.success, lineWidth: 1))
                            .foregroundStyle(Theme.success)
                    }
                    .disabled(busy || !canPay)
                    .accessibilityIdentifier("payroll-mark-paid-\(row.worker.id)")
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 1))
    }
}
