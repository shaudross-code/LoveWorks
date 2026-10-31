import SwiftUI

struct MySizesView: View {
    @StateObject private var state = SizesFormState(data: nil)
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = true
    @State private var errorMsg: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView().tint(.white)
                } else if let err = errorMsg {
                    VStack {
                        Text(err).foregroundColor(Theme.danger)
                        Button("Retry") { Task { await load() } }
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(8)
                    }
                } else {
                    SizesFormView(state: state, isAdmin: false) { dict, fit, units in
                        Task { await save(dict: dict, fit: fit, units: units) }
                    }
                }
            }
            .navigationTitle("My Sizes")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.textMain)
                    }
                }
#else
                ToolbarItem(placement: .automatic) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.textMain)
                    }
                }
#endif
            }
            .task { await load() }
        }
    }
    
    private func load() async {
        isLoading = true
        errorMsg = nil
        do {
            let data = try await APIClient.shared.fetchSizes(workerId: nil)
            await MainActor.run {
                let newState = SizesFormState(data: data)
                self.state.fit = newState.fit
                self.state.units = newState.units
                self.state.shoeScale = newState.shoeScale
                self.state.values = newState.values
                self.state.canon = newState.canon
                self.state.originalValues = newState.originalValues
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMsg = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func save(dict: [String: AnyValue], fit: String, units: MeasurementUnit) async {
        do {
            let _ = try await APIClient.shared.updateSizes(workerId: nil, values: dict, fit: fit, units: units.rawValue, notifyWorker: false)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { self.errorMsg = error.localizedDescription }
        }
    }
}
