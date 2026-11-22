//
//  WatchHomeView.swift
//  iLoveWorksWatch
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject private var model: WatchCaloriesModel

    private let gold = Color(red: 0.98, green: 0.80, blue: 0.08)
    private let pink = Color(red: 1.0, green: 0.36, blue: 0.62)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("ACTIVE")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(pink)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(model.displayActive))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("kcal").font(.system(size: 13))
                }
                .monospacedDigit()
                Text("TOTAL \(Int(model.displayTotal)) kcal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                if model.isLive, let start = model.liveStart {
                    Text(start, style: .timer)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(gold)
                        .monospacedDigit()
                }

                Button(action: { model.toggleLive() }) {
                    Label(model.isLive ? "Stop live" : "Start live", systemImage: model.isLive ? "stop.fill" : "flame.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(model.isLive ? .red : gold)
                .disabled(!model.authorized)
                .padding(.top, 4)

                if !model.authorized {
                    Button("Allow Health access") { Task { await model.start() } }
                        .font(.footnote)
                }
                Text(model.phoneReachable ? "iPhone connected" : "iPhone not nearby, will sync later")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                if let m = model.message {
                    Text(m).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task { await model.start() }
    }
}
