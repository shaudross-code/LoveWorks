import SwiftUI

/// Admin: view and edit one worker's sizes, optionally notifying them of exactly what changed.
struct WorkerSizesView: View {
    let worker: User
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = SizesFormModel()
    @State private var notify = true
    @State private var isLoading = true
    @State private var saving = false
    @State private var errorMsg: String?
    @State private var resultMsg: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("You're editing \(worker.name)'s sizes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.primaryHover)
                        LastUpdatedView(doc: model.doc)
                    }
                    if isLoading {
                        ProgressView().tint(Theme.lovePink).frame(maxWidth: .infinity).padding(40)
                    } else {
                        SizesFormView(model: model)
                        Toggle(isOn: $notify) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notify \(worker.name)").font(.system(size: 14, weight: .semibold))
                                Text("Sends them exactly what changed.").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                            }
                        }
                        .tint(Theme.lovePink)
                        .padding()
                        .background(Theme.surface)
                        .cornerRadius(14)
                        if let resultMsg {
                            Label(resultMsg, systemImage: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.success)
                        }
                        if let errorMsg {
                            Text(errorMsg).font(.system(size: 13)).foregroundStyle(Theme.danger)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("\(worker.name) · Sizes")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(saving || isLoading)
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        do {
            let res: WorkerSizesResponse = try await APIClient.shared.request("/workers/\(worker.id)/sizes")
            model.load(res.sizes)
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        saving = true
        errorMsg = nil
        resultMsg = nil
        do {
            let res: SizesSaveResponse = try await APIClient.shared.send(
                "/workers/\(worker.id)/sizes", method: "PUT",
                json: SizesUpdateBody(fit: model.form.fit, units: nil, values: model.form.payload(), notify: notify)
            )
            model.load(res.sizes)
            let n = res.changes?.count ?? 0
            if n == 0 { resultMsg = "No changes to save." }
            else { resultMsg = "Saved \(n) change\(n == 1 ? "" : "s")\(res.notified == true ? " · \(worker.name) was notified" : "")." }
        } catch {
            errorMsg = error.localizedDescription
        }
        saving = false
    }
}
