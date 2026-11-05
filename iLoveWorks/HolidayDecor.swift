//
//  HolidayDecor.swift
//  iLoveWorks
//

import SwiftUI

/// Small greeting pill for headers, e.g. "🎃 Happy Halloween".
struct HolidayBadge: View {
    @ObservedObject private var store = ThemeStore.shared
    var compact = false

    var body: some View {
        if let t = store.theme {
            HStack(spacing: 6) {
                Text(t.emoji)
                if !compact {
                    Text(t.greeting)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Theme.primary.opacity(0.1))
            .foregroundStyle(Theme.primaryHover)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.primary.opacity(0.3), lineWidth: 1))
        }
    }
}

/// Gentle drifting holiday emojis behind the UI (never blocks touches).
struct HolidayFloaters: View {
    @ObservedObject private var store = ThemeStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let t = store.theme, !t.emojis.isEmpty {
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { ctx in
                    let time = ctx.date.timeIntervalSinceReferenceDate
                    ZStack {
                        ForEach(0..<9, id: \.self) { i in
                            let duration = Double(22 + (i * 5) % 16)
                            let phase = ((time + Double(i) * 3.7) / duration).truncatingRemainder(dividingBy: 1)
                            let travel = geo.size.height + 80
                            Text(t.emojis[i % t.emojis.count])
                                .font(.system(size: CGFloat(16 + (i * 7) % 14)))
                                .opacity(0.22)
                                .position(
                                    x: geo.size.width * CGFloat((i * 11 + 4) % 96) / 100,
                                    y: reduceMotion ? geo.size.height * CGFloat(i + 1) / 10 : geo.size.height + 40 - travel * phase
                                )
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
