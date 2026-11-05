import SwiftUI

/// My Sizes tab — the signed-in user's own sizes (workers and admins).
struct MySizesView: View {
    @StateObject private var model = SizesFormModel()
    @State private var isLoading = true
    @State private var saving = false
    @State private var message: String?
    @State private var errorMsg: String?
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if isLoading {
                        ProgressView().tint(Theme.lovePink).frame(maxWidth: .infinity).padding(40)
                    } else {
                        SizesFormView(model: model)
                        actions
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .background(Theme.background.ignoresSafeArea())
            .refreshable { await load() }
            .task { await load() }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .confirmationDialog("Clear all your sizes?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear everything", role: .destructive) { Task { await clearAll() } }
            } message: {
                Text("This removes every measurement and size you've saved.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FITS · GEAR")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Theme.lovePink)
                    .tracking(1.5)
                Spacer()
                HolidayBadge(compact: true)
            }
            Text("My Sizes")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.textMain)
            Text("Saved to your account, so they follow you to any phone or computer. Your admin can see and update these to order the right gear.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textMuted)
            LastUpdatedView(doc: model.doc)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if let message {
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.success)
            }
            if let errorMsg {
                Text(errorMsg).font(.system(size: 13)).foregroundStyle(Theme.danger)
            }
            Button { Task { await save() } } label: {
                HStack {
                    if saving { ProgressView().tint(.white) } else { Text("Save sizes").font(.system(size: 16, weight: .bold)) }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.loveGradient)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .disabled(saving)

            Button("Clear all my sizes", role: .destructive) { confirmClear = true }
                .font(.system(size: 13, weight: .medium))
                .disabled(model.doc?.updatedAt == nil)
        }
    }

    private func load() async {
        do {
            let doc: SizesDoc = try await APIClient.shared.request("/sizes/me")
            model.load(doc)
            errorMsg = nil
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        saving = true
        message = nil
        errorMsg = nil
        do {
            let res: SizesSaveResponse = try await APIClient.shared.send("/sizes/me", method: "PUT", json: SizesUpdateBody(fit: model.form.fit, units: model.units.rawValue, values: model.form.payload()))
            model.load(res.sizes)
            let n = res.changes?.count ?? 0
            message = n == 0 ? "No changes — you're all set." : "Saved \(n) change\(n == 1 ? "" : "s")."
        } catch {
            errorMsg = error.localizedDescription
        }
        saving = false
    }

    private func clearAll() async {
        do {
            let doc: SizesDoc = try await APIClient.shared.request("/sizes/me", method: "DELETE")
            model.load(doc)
            message = "All sizes cleared."
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

struct SizesUpdateBody: Encodable {
    let fit: String?
    let units: String?
    let values: [String: AnyValue]
    var notify: Bool? = nil
}

struct LastUpdatedView: View {
    let doc: SizesDoc?

    var body: some View {
        if let at = doc?.updatedAt {
            HStack(spacing: 6) {
                Image(systemName: "clock").font(.system(size: 11))
                Text("Updated \(APIDate.day(at))\(doc?.updatedBy?.name.map { " by \($0)" } ?? "")")
                    .font(.system(size: 12))
                if SizeHelper.isStale(at) {
                    Text("Over a year old — worth a re-measure")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(Theme.textMuted)
        } else {
            Text("Nothing saved yet.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textMuted)
        }
    }
}
