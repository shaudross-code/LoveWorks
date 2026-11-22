//
//  ScaleWeighInView.swift
//  iLoveWorks
//
//  Sheet that walks the worker through a Bluetooth weigh-in. The reading saves (and is shared
//  with the admin when sharing is on) as soon as the scale settles; Undo takes it back.
//

#if os(iOS) && canImport(CoreBluetooth) && canImport(HealthKit)
import SwiftUI
import UIKit

struct ScaleWeighInView: View {
    @ObservedObject private var scale = ScaleBluetooth.shared
    @ObservedObject private var health = HealthSync.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("ilw.scale.saveToHealth") private var alsoHealth = true
    @State private var saved = false
    @State private var undoing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 22) {
                    Image(systemName: icon)
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(scale.phase == .got ? Theme.success : Theme.primary)
                        .symbolEffect(.pulse, isActive: busy)
                        .padding(.top, 30)
                    content
                    if health.connected && busy {
                        Toggle("Also save to Apple Health", isOn: $alsoHealth)
                            .tint(Theme.primary)
                            .foregroundStyle(Theme.textMain)
                            .accessibilityIdentifier("scale-save-health")
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Weigh in")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.accessibilityIdentifier("scale-close")
                }
            }
        }
        .onAppear { scale.start() }
        .onDisappear { scale.cancel() }
        .onChange(of: scale.reading) { _, reading in
            guard let reading else { return }
            saved = false
            Task {
                await health.applyScale(kg: reading.kg, at: reading.at, saveToHealth: health.connected && alsoHealth)
                saved = true
            }
        }
    }

    private var busy: Bool { [.searching, .connecting, .weighing].contains(scale.phase) }

    private var icon: String {
        switch scale.phase {
        case .got: return "checkmark.circle.fill"
        case .bluetoothOff, .denied: return "antenna.radiowaves.left.and.right.slash"
        case .unsupported, .timedOut, .failed: return "exclamationmark.triangle.fill"
        default: return "scalemass.fill"
        }
    }

    @ViewBuilder private var content: some View {
        switch scale.phase {
        case .idle, .searching:
            Status(title: "Step on your scale", detail: "iLoveWorks is looking for your scale. Close the VeSync app first, since a scale talks to one app at a time.")
            ProgressView().tint(Theme.primary)
        case .connecting:
            Status(title: "Connecting to \(scale.foundName ?? "scale")…", detail: "Stay on the scale.")
            ProgressView().tint(Theme.primary)
        case .weighing:
            Status(title: "Hold still…", detail: "Reading your weight from \(scale.foundName ?? "the scale").")
            ProgressView().tint(Theme.primary)
        case .got:
            if let r = scale.reading { result(r) }
        case .unsupported:
            Status(title: "This scale can't be read directly", detail: "Your VeSync scale doesn't share weight with other apps over Bluetooth. Turn on VeSync → Apple Health instead and iLoveWorks picks it up from there.")
            retry
        case .bluetoothOff:
            Status(title: "Bluetooth is off", detail: "Turn on Bluetooth in Control Center, then try again.")
            retry
        case .denied:
            Status(title: "Bluetooth isn't allowed", detail: "Allow Bluetooth for iLoveWorks in Settings to read your scale.")
            PrimaryButton(title: "Open Settings", id: "scale-open-settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        case .timedOut:
            Status(title: "No reading yet", detail: "Make sure the scale is close by, close the VeSync app, then step on and try again.")
            retry
        case .failed(let msg):
            Status(title: "Something went wrong", detail: msg)
            retry
        }
    }

    private var retry: some View {
        PrimaryButton(title: "Try again", id: "scale-retry") { scale.start() }
    }

    @ViewBuilder private func result(_ r: ScaleReading) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", r.kg * 2.20462))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textMain)
                .monospacedDigit()
                .accessibilityIdentifier("scale-reading")
            Text("lb · \(String(format: "%.1f", r.kg)) kg").font(.system(size: 14)).foregroundStyle(Theme.textMuted)
        }
        Text(!saved ? "Saving…" : health.shareWithAdmin ? "Saved and shared with your admin." : "Saved. Sharing with your admin is off.")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(saved ? Theme.success : Theme.textMuted)
            .accessibilityIdentifier("scale-saved-status")
        PrimaryButton(title: "Done", id: "scale-done") { dismiss() }
        Button(undoing ? "Undoing…" : "Undo") {
            undoing = true
            Task {
                await health.undoScale()
                undoing = false
                dismiss()
            }
        }
        .disabled(!saved || undoing || !health.canUndoScale)
        .foregroundStyle(Theme.textMuted)
        .accessibilityIdentifier("scale-undo")
    }

    private struct Status: View {
        let title: String
        let detail: String

        var body: some View {
            VStack(spacing: 8) {
                Text(title).font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.textMain).multilineTextAlignment(.center)
                Text(detail).font(.system(size: 14)).foregroundStyle(Theme.textMuted).multilineTextAlignment(.center)
            }
        }
    }

    private struct PrimaryButton: View {
        let title: String
        let id: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .foregroundStyle(.black)
                    .cornerRadius(100)
            }
            .accessibilityIdentifier(id)
        }
    }
}
#endif
