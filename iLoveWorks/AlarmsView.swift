//
//  AlarmsView.swift
//  iLoveWorks
//

import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

struct AlarmsView: View {
    @ObservedObject private var store = AlarmStore.shared
    @ObservedObject private var push = PushManager.shared
    @State private var draft: AlarmDraft?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(eyebrow: "REMINDERS", title: "Alarms")
                    AlarmPermissionCard(status: push.status)
                        .padding(.horizontal)

                    Button(action: { draft = AlarmDraft() }) {
                        Label("New alarm", systemImage: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.primary)
                            .foregroundStyle(.black)
                            .cornerRadius(100)
                    }
                    .padding(.horizontal)

                    if let err = store.lastError {
                        Text(err).font(.system(size: 13)).foregroundStyle(Theme.danger).padding(.horizontal)
                    }

                    if store.upcoming.isEmpty {
                        EmptyStateView(icon: "alarm", title: "No alarms yet", message: "Tap the alarm icon on a task, or New alarm.")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(store.upcoming) { a in
                                AlarmRowView(alarm: a) { Task { await store.cancel(a) } }
                            }
                        }
                        .padding(.horizontal)
                    }
                    Spacer(minLength: 40)
                }
            }
            .refreshable { await store.sync() }
        }
        .navigationTitle("Alarms")
        .inlineNavigationTitle()
        .sheet(item: $draft) { AlarmEditorView(draft: $0) }
        .task {
            await push.refreshStatus()
            await store.sync()
        }
    }
}

struct AlarmRowView: View {
    let alarm: AlarmItem
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "alarm.fill").foregroundStyle(Theme.primary)
            VStack(alignment: .leading, spacing: 3) {
                Text(alarm.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textMain).lineLimit(2)
                Text(Self.label(alarm.fireAt)).font(.system(size: 12)).foregroundStyle(Theme.textMuted)
            }
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "trash").foregroundStyle(Theme.danger)
            }
            .accessibilityLabel("Cancel alarm")
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }

    static func label(_ iso: String) -> String {
        guard let d = APIDate.parse(iso) else { return iso }
        return d.formatted(date: .abbreviated, time: .shortened)
    }
}

struct AlarmPermissionCard: View {
    let status: UNAuthorizationStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
            Text(message).font(.system(size: 13)).foregroundStyle(Theme.textMuted)
            if status == .notDetermined {
                Button("Allow alarms") { Task { _ = await PushManager.shared.enable() } }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.primary)
            }
            #if canImport(UIKit)
            if status == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.primary)
            }
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }

    private var allowed: Bool { status == .authorized || status == .provisional }
    private var title: String { allowed ? "Alarms will ring" : status == .denied ? "Alarms are blocked" : "Allow alarms" }
    private var icon: String { allowed ? "checkmark.circle.fill" : status == .denied ? "xmark.octagon.fill" : "bell.badge" }
    private var color: Color { allowed ? Theme.success : status == .denied ? Theme.danger : Theme.primary }
    private var message: String {
        if allowed { return "They ring on this iPhone even when iLoveWorks is closed. They follow your Ring/Silent switch and Focus settings." }
        if status == .denied { return "Notifications are off for iLoveWorks, so alarms can't ring. Turn them on in Settings → Notifications → iLoveWorks." }
        return "iPhone needs your permission before an alarm can ring."
    }
}

struct AlarmEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AlarmDraft
    @State private var note = ""
    @State private var saving = false
    @State private var error: String?

    init(draft: AlarmDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Alarm") {
                    TextField("What's it for?", text: $draft.title)
                    DatePicker("Rings at", selection: $draft.date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    TextField("Note (optional)", text: $note)
                }
                Section {
                    Text("Rings with the iLoveWorks alarm sound, even with the app closed. Long-press the alert to Snooze or Stop.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textMuted)
                }
                if let error {
                    Section { Text(error).foregroundStyle(Theme.danger) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Set alarm")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") { save() }
                        .disabled(saving || draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        saving = true
        error = nil
        Task {
            if PushManager.shared.status == .notDetermined { _ = await PushManager.shared.enable() }
            do {
                let trimmedNote = note.trimmingCharacters(in: .whitespaces)
                try await AlarmStore.shared.create(
                    title: draft.title.trimmingCharacters(in: .whitespaces),
                    at: draft.date,
                    note: trimmedNote.isEmpty ? nil : trimmedNote,
                    taskId: draft.taskId
                )
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            saving = false
        }
    }
}
