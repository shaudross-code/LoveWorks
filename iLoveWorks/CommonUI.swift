//
//  CommonUI.swift
//  iLoveWorks
//

import SwiftUI

struct GoalCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textMain)
                Spacer()
                if let target = goal.targetAmount {
                    Text("$\(Int(target))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.lovePink)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Theme.secondary)
                            .frame(height: 8)
                        
                        Rectangle()
                            .fill(Theme.loveGradient)
                            .frame(width: geo.size.width * CGFloat(min(goal.progress.pctOfTarget ?? 0, 100) / 100.0), height: 8)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(Int(goal.progress.pctOfTarget ?? 0))% reached")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                    Text("$\(Int(goal.progress.week)) this week")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.lovePink)
                }
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.lovePink.opacity(0.15), lineWidth: 1)
        )
    }
}

struct EssentialCard: View {
    let essential: Essential
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(essential.purchased ? Color.green.opacity(0.4) : Theme.border, lineWidth: 1)
                        .frame(width: 32, height: 32)
                    if essential.purchased {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(essential.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(essential.purchased ? Theme.textMuted : Theme.textMain)
                        .strikethrough(essential.purchased)
                    
                    Text(essential.category.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor().opacity(0.15))
                        .foregroundStyle(categoryColor())
                        .cornerRadius(4)
                }
                
                if let note = essential.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", essential.price * Double(essential.quantity)))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.lovePink)
                Text("QTY \(essential.quantity)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
    }
    
    private func categoryColor() -> Color {
        switch essential.category {
        case "household": return .blue
        case "groceries": return .green
        case "kids": return .purple
        case "everyday": return .orange
        case "personal": return .pink
        default: return Theme.textMuted
        }
    }
}

struct WeeklyStripView: View {
    let activity: [WeeklyDay]
    let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7) { index in
                let dayActivity = index < activity.count ? activity[index] : nil
                VStack(spacing: 8) {
                    Text(days[index])
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                    
                    Circle()
                        .fill((dayActivity?.count ?? 0) > 0 ? Theme.lovePink : Theme.secondary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\((dayActivity?.count ?? 0))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle((dayActivity?.count ?? 0) > 0 ? .white : Theme.textMuted)
                        )
                    
                    if (dayActivity?.count ?? 0) >= 3 {
                        Text("🔥")
                            .font(.system(size: 10))
                    } else {
                        Spacer().frame(height: 10)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.lovePink.opacity(0.15), lineWidth: 1)
        )
    }
}

enum DeadlineTone { case red, yellow, sky, zinc }

struct DeadlineBucket: View {
    let title: String
    let tasks: [TaskItem]
    let tone: DeadlineTone
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(toneColor().opacity(0.1))
                .foregroundStyle(toneColor())
                .cornerRadius(100)
                .overlay(Capsule().stroke(toneColor().opacity(0.3), lineWidth: 1))
                
                Spacer()
                Text("\(tasks.count)")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
            }
            
            if tasks.isEmpty {
                Text("Quiet for now.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(3)) { task in
                        HStack {
                            Circle()
                                .fill(Theme.textMuted.opacity(0.3))
                                .frame(width: 4, height: 4)
                            Text(task.title)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMain)
                                .lineLimit(1)
                            Spacer()
                            Text("$\(Int(task.price))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.lovePink)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
    }
    
    private func toneColor() -> Color {
        switch tone {
        case .red: return .red
        case .yellow: return Theme.primary
        case .sky: return .blue
        case .zinc: return .zinc
        }
    }
}

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onStart: () -> Void
    let onSpeak: (String) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(task.status == "completed" ? Color.green.opacity(0.4) : Theme.border, lineWidth: 1)
                        .frame(width: 32, height: 32)
                    if task.status == "completed" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(task.status == "completed" ? Theme.textMuted : Theme.textMain)
                        .strikethrough(task.status == "completed")
                    
                    if let desc = task.description {
                        Button(action: { onSpeak(desc) }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.lovePink)
                        }
                    }
                    
                    if let freq = task.frequency, freq != "once" {
                        MetadataChip(label: freq, icon: "repeat", color: .blue)
                    }
                    
                    if let payout = task.payoutSchedule, payout != "per_task" {
                        MetadataChip(label: "paid \(payout)", icon: "wallet.pass.fill", color: .green)
                    }
                }
                
                if let desc = task.description, task.status != "completed" {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text("$\(String(format: "%.2f", task.price))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.lovePink)
                
                if task.status != "completed" {
                    Button(action: onStart) {
                        Text(task.status == "in_progress" ? "WORKING…" : "START")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(task.status == "in_progress" ? Theme.lovePink.opacity(0.1) : .clear)
                            .foregroundStyle(task.status == "in_progress" ? Theme.lovePink : Theme.textMuted)
                            .cornerRadius(100)
                            .overlay(RoundedRectangle(cornerRadius: 100).stroke(task.status == "in_progress" ? Theme.lovePink.opacity(0.3) : Theme.border, lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
    }
}

struct MetadataChip: View {
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label.uppercased())
                .font(.system(size: 8, weight: .black))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .cornerRadius(4)
        .tracking(0.5)
    }
}

struct NotificationsView: View {
    let notifications: [NotificationItem]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if notifications.isEmpty {
                    Text("No notifications")
                        .foregroundStyle(Theme.textMuted)
                } else {
                    List {
                        ForEach(notifications) { notif in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notif.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(notif.read ? Theme.textMuted : Theme.textMain)
                                if let body = notif.body {
                                    Text(body)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.textMuted)
                                }
                            }
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
