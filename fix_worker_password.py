import re

with open("iLoveWorks/AdminViewModel.swift", "r") as f:
    text = f.read()

old_req = """    struct WorkerUpdateRequest: Encodable {
        let name: String?
        let email: String?
    }"""
new_req = """    struct WorkerUpdateRequest: Encodable {
        let name: String?
        let email: String?
        let password: String?
    }"""
text = text.replace(old_req, new_req)

with open("iLoveWorks/AdminViewModel.swift", "w") as f:
    f.write(text)


with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

old_state = """    @State private var email: String
    @State private var isSubmitting = false"""
new_state = """    @State private var email: String
    @State private var password = ""
    @State private var isSubmitting = false"""
text = text.replace(old_state, new_state)

old_view = """                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                                .padding(.bottom, 20)
                        }

                        Button(action: saveChanges) {"""

new_view = """                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NEW PASSWORD (OPTIONAL)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            SecureField("Enter new password", text: $password)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                                .padding(.bottom, 20)
                        }

                        Button(action: saveChanges) {"""

text = text.replace(old_view, new_view)

old_save = """    private func saveChanges() {
        isSubmitting = true
        let req = AdminViewModel.WorkerUpdateRequest(
            name: name,
            email: email
        )"""
new_save = """    private func saveChanges() {
        isSubmitting = true
        let req = AdminViewModel.WorkerUpdateRequest(
            name: name,
            email: email,
            password: password.isEmpty ? nil : password
        )"""

text = text.replace(old_save, new_save)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)

