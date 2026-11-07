import re

with open("iLoveWorks/AdminViewModel.swift", "r") as f:
    text = f.read()

# Add deleteWorker
if "func deleteWorker" not in text:
    delete_func_str = """    func deleteWorker(workerId: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.request("/workers/\\(workerId)", method: "DELETE")
        await refreshDashboard()
    }
"""
    create_worker = "func createWorker(name: String, email: String, password: String) async throws {"
    text = text.replace(create_worker, delete_func_str + "\n    " + create_worker)

with open("iLoveWorks/AdminViewModel.swift", "w") as f:
    f.write(text)

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Add editingWorker
if "editingWorker: Worker?" not in text:
    old = "@State private var showingAddWorker = false"
    new = "@State private var showingAddWorker = false\n    @State private var editingWorker: Worker? = nil"
    text = text.replace(old, new)
    
    old_card = "AdminWorkerCard(status: status)"
    new_card = "AdminWorkerCard(status: status)\n                                    .contentShape(Rectangle())\n                                    .onTapGesture { editingWorker = status.worker }"
    text = text.replace(old_card, new_card)

# Inject EditWorkerModal definition and hook up to AdminWorkersView array
if "struct EditWorkerModal" not in text:
    modal = """
struct EditWorkerModal: View {
    let worker: Worker
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\\.presentationMode) var presentationMode
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 64))
                            .foregroundStyle(.red)
                            .padding(.top, 40)
                            
                        Text(worker.name)
                            .font(.title)
                            .foregroundStyle(Theme.textMain)
                            .bold()
                            
                        Text(worker.email)
                            .foregroundStyle(Theme.textMuted)

                        Button(action: deleteWorker) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                } else {
                                    Text("REMOVE WORKER PERMANENTLY")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .cornerRadius(100)
                        }
                        .disabled(isSubmitting)
                        .padding(.top, 40)
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Manage Worker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
    
    private func deleteWorker() {
        isSubmitting = true
        Task {
            try? await viewModel.deleteWorker(workerId: worker.id)
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}
"""
    text += modal

# Put it in AdminWorkersView
if ".sheet(item: $editingWorker)" not in text:
    old = ".sheet(isPresented: $showingAddWorker) {"
    new = ".sheet(item: $editingWorker) { worker in\n                EditWorkerModal(worker: worker, viewModel: viewModel)\n            }\n            .sheet(isPresented: $showingAddWorker) {"
    text = text.replace(old, new)


with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)

