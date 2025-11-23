import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    
    @Binding var email: String
    @State private var info = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    Button("Send Reset Email") {
                        Task {
                            let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
                            info = await session.forgotPassword(email: e)
                                ?? "If account exists, reset email sent."
                        }
                    }
                    
                    if !info.isEmpty {
                        Text(info)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("SEND RESET EMAIL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Forgot Password")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
