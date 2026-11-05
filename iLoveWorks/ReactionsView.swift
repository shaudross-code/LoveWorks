//
//  ReactionsView.swift
//  iLoveWorks
//
//  Emoji reactions on goals and trips (same 8 emojis as the web app). Tap a chip to toggle
//  your own reaction, or "React" to pick one. The picker closes when you tap anywhere else.
//

import SwiftUI

struct ReactionsView: View {
    let goal: Goal
    let onChange: ([GoalReaction]) -> Void

    @EnvironmentObject private var session: SessionManager
    @State private var showingPicker = false
    @State private var busy = false
    @State private var error: String?

    static let emojis = ["👍", "❤️", "🔥", "🎉", "⭐", "💪", "🙌", "💎"]

    private var groups: [(emoji: String, count: Int, mine: Bool)] {
        let me = session.currentUser?.id
        var order: [String] = []
        var counts: [String: (Int, Bool)] = [:]
        for r in goal.reactions ?? [] {
            if counts[r.emoji] == nil { order.append(r.emoji) }
            let c = counts[r.emoji] ?? (0, false)
            counts[r.emoji] = (c.0 + 1, c.1 || r.byId == me)
        }
        return order.map { (emoji: $0, count: counts[$0]!.0, mine: counts[$0]!.1) }.sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FlowLayout(spacing: 6) {
                ForEach(groups, id: \.emoji) { g in
                    Button { toggle(g.emoji) } label: {
                        HStack(spacing: 4) {
                            Text(g.emoji).font(.system(size: 13))
                            Text("\(g.count)").font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(g.mine ? Theme.primary.opacity(0.15) : Color.zinc.opacity(0.6))
                        .foregroundStyle(g.mine ? Theme.primaryHover : Theme.textMuted)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(g.mine ? Theme.primary.opacity(0.4) : Color.zinc, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(g.mine ? "Remove your \(g.emoji) reaction" : "React \(g.emoji)")
                }

                Button { showingPicker = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "face.smiling").font(.system(size: 11))
                        Text("React").font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(Theme.primaryHover)
                    .overlay(Capsule().stroke(Theme.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3])))
                }
                .buttonStyle(.plain)
                .disabled(busy)
                .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Self.emojis, id: \.self) { e in
                                Button { toggle(e) } label: {
                                    Text(e)
                                        .font(.system(size: 22))
                                        .frame(width: 44, height: 44)
                                        .background(Theme.primary.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxWidth: 320)
                    .presentationCompactAdaptation(.popover)
                    .presentationBackground(Theme.surface)
                }
            }

            if let error {
                Text(error).font(.system(size: 10)).foregroundStyle(Theme.danger)
            }
        }
    }

    private func toggle(_ emoji: String) {
        showingPicker = false
        busy = true
        error = nil
        Task {
            do {
                let updated: Goal = try await APIClient.shared.send("/goals/\(goal.id)/react", json: ["emoji": emoji])
                onChange(updated.reactions ?? [])
            } catch {
                self.error = error.localizedDescription
            }
            busy = false
        }
    }
}
