import SwiftUI
import Combine
import AVFoundation

public class SpeechManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    public init() {}
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        // Enforce audio routing just in case
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            if #available(iOS 27.0, *) {
                AVAudioSession.sharedInstance().activate(options: []) { success, error in }
            } else {
                try AVAudioSession.sharedInstance().setActive(true)
            }
        } catch {}
        
        // Stop before speaking to avoid queued overlap blocks
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Re-insist upon playback modality immediately before invoking the utterance
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                if #available(iOS 27.0, *) {
                    AVAudioSession.sharedInstance().activate(options: []) { success, error in
                        DispatchQueue.main.async {
                            self.synthesizer.speak(utterance)
                        }
                    }
                    return
                } else {
                    try AVAudioSession.sharedInstance().setActive(true)
                }
            } catch {}
            
            self.synthesizer.speak(utterance)
        }
    }
}
//
//  CommonUI.swift
//  iLoveWorks
//

import SwiftUI

struct GoalCard: View {
    let goal: Goal
    /// When set, shows the reactions row and lets the signed-in user react.
    var onReactionsChange: (([GoalReaction]) -> Void)? = nil

    var body: some View {
                VStack(alignment: .leading, spacing: 12) {
            if let imageUrlStr = goal.imageUrl, let url = URL(string: APIClient.shared.fullURL(for: imageUrlStr)) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 180)
                            .clipped()
                            .cornerRadius(12)
                    } else if phase.error != nil {
                        Rectangle()
                            .fill(Theme.secondary.opacity(0.3))
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .cornerRadius(12)
                            .overlay(Image(systemName: "photo").foregroundStyle(.gray.opacity(0.5)))
                    } else {
                        Rectangle()
                            .fill(Theme.secondary.opacity(0.3))
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .cornerRadius(12)
                            .overlay(ProgressView())
                    }
                }
                .padding(.bottom, 4)
            }
            
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textMain)
                        .lineLimit(2)
                    if let owner = goal.owner?.name {
                        Text(owner)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }
                    if let period = goal.period {
                        Text("Due: " + period)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.danger)
                    }
                }

                if let link = goal.productLink, let url = URL(string: link) {
                    Link(destination: url) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.primary)
                    }
                }
                Spacer()
                if let target = goal.targetAmount {
                    Text(Fmt.money(target))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.lovePink)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Theme.secondary)
                            .frame(height: 8)
                        Rectangle()
                            .fill(Theme.loveGradient)
                            .frame(width: geo.size.width * CGFloat(min(goal.pct, 100) / 100.0), height: 8)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)

                HStack {
                    Text("\(Int(goal.pct))% reached")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                    Text("\(Fmt.money(goal.weekAmount)) this week")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.lovePink)
                }
            }

            if let onReactionsChange {
                ReactionsView(goal: goal, onChange: onReactionsChange)
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
    @State private var selected: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let count = index < activity.count ? activity[index].count : 0
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { selected = selected == index ? nil : index }
                    } label: {
                        VStack(spacing: 8) {
                            Text(days[index])
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(selected == index ? Theme.lovePink : Theme.textMuted)
                            Circle()
                                .fill(count > 0 ? Theme.lovePink : Theme.secondary)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("\(count)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(count > 0 ? .white : Theme.textMuted)
                                )
                                .overlay(Circle().stroke(selected == index ? Theme.primary : .clear, lineWidth: 2))
                            Text(count >= 3 ? "🔥" : " ")
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let i = selected, i < activity.count {
                let d = activity[i]
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Weekday.names[i]) · \(d.count) done · \(Fmt.money(d.earned)) · \(String(format: "%.1fh", d.hours))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textMain)
                    ForEach(Array((d.titles ?? []).prefix(5).enumerated()), id: \.offset) { _, title in
                        Text("• \(title)")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
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
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
        case .zinc: return Theme.textMuted
        }
    }
}

struct TaskRow: View {
    let task: TaskItem
    var showAssignee = false
    let onToggle: () -> Void
    let onStart: () -> Void
    let onSpeak: (String) -> Void
    var onSaveAlarm: ((String?) -> Void)? = nil

    @State private var showingAlarm = false
    @State private var draftAlarmTime = Date()

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.green.opacity(0.4) : Theme.border, lineWidth: 1)
                        .frame(width: 32, height: 32)
                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? Theme.textMuted : Theme.textMain)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)

                    if let desc = task.description, !desc.isEmpty {
                        Button(action: { onSpeak(desc) }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.lovePink)
                        }
                    }
                }

                FlowLayout(spacing: 6) {
                    if let due = TaskSchedule.dueLabel(task) {
                        MetadataChip(label: due, icon: "calendar", color: Theme.primary)
                    }
                    if let freq = task.frequency, freq != "once" {
                        MetadataChip(label: freq, icon: "repeat", color: .blue)
                    }
                    if let payout = task.payoutSchedule, payout != "per_task" {
                        MetadataChip(label: "paid \(payout)", icon: "wallet.pass.fill", color: .green)
                    }
                    if showAssignee, let name = task.assigneeName {
                        MetadataChip(label: name, icon: "person.fill", color: Theme.textMuted)
                    }
                    if let adminAlarm = task.adminAlarm {
                         MetadataChip(label: adminAlarm + " (Mandatory)", icon: "bell.fill", color: Theme.danger)
                    } else {
                         if onSaveAlarm != nil {
                             Button(action: { showingAlarm = true }) {
                                 MetadataChip(label: task.userAlarm ?? "Set Alarm", icon: task.userAlarm != nil ? "bell.fill" : "bell", color: task.userAlarm != nil ? .orange : Theme.textMuted)
                             }
                         }
                    }
                }
                .sheet(isPresented: $showingAlarm) {
                    NavigationView {
                        VStack(spacing: 24) {
                            DatePicker("Select Alarm Time", selection: $draftAlarmTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .padding()
                            
                            Button(action: {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                let str = formatter.string(from: draftAlarmTime)
                                onSaveAlarm?(str)
                                showingAlarm = false
                            }) {
                                Text("Save Alarm")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.loveGradient)
                                    .foregroundStyle(.white)
                                    .cornerRadius(100)
                            }
                            .padding(.horizontal, 24)
                            
                            if task.userAlarm != nil {
                                Button("Remove Alarm") {
                                    onSaveAlarm?(nil)
                                    showingAlarm = false
                                }
                                .foregroundStyle(Theme.danger)
                                .padding(.top, 8)
                            }
                            Spacer()
                        }
                        .navigationTitle("Task Alarm")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showingAlarm = false }
                            }
                        }
                    }
                    .presentationDetents([.fraction(0.6)])
                }

                if let desc = task.description, !desc.isEmpty, !task.isCompleted {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 8) {
                Text("$\(String(format: "%.2f", task.price))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.lovePink)

                if !task.isCompleted {
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
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .cornerRadius(4)
        .tracking(0.5)
    }
}

struct NotificationsView: View {
    let notifications: [NotificationItem]
    var onAppear: () -> Void = {}
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
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
                                if let body = notif.body, !body.isEmpty {
                                    Text(body)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.textMuted)
                                }
                                Text(APIDate.short(notif.createdAt))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textMuted.opacity(0.7))
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
        .onAppear(perform: onAppear)
    }
}

/// Wraps children onto new lines (chips, reactions).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for i in row.items {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row { var items: [Int] = []; var y: CGFloat = 0; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for (i, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            if !current.items.isEmpty && current.width + spacing + size.width > width {
                rows.append(current)
                current = Row(y: current.y + current.height + spacing)
            }
            current.width += (current.items.isEmpty ? 0 : spacing) + size.width
            current.height = max(current.height, size.height)
            current.items.append(i)
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}

/// Section label used on forms.
struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Theme.textMuted)
            .tracking(1)
    }
}

extension View {
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        return self.navigationBarTitleDisplayMode(.inline)
        #else
        return self
        #endif
    }

    func decimalKeyboard() -> some View {
        #if os(iOS)
        return self.keyboardType(.decimalPad)
        #else
        return self
        #endif
    }

    func numberKeyboard() -> some View {
        #if os(iOS)
        return self.keyboardType(.numberPad)
        #else
        return self
        #endif
    }

    func emailField() -> some View {
        #if os(iOS)
        return self.keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
        #else
        return self.autocorrectionDisabled()
        #endif
    }

    func fieldBox() -> some View {
        self.padding()
            .background(Theme.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
    }
}
