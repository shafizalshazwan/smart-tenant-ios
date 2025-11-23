import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    
    @Binding var email: String
    @State private var token = ""
    @State private var newPass = ""
    @State private var info = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("RESET PASSWORD") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    TextField("Reset token", text: $token)
                        .keyboardType(.numberPad)
                    
                    SecureField("New password", text: $newPass)
                    
                    Button("Reset Now") {
                        Task {
                            let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
                            let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
                            let p = newPass.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            info = await session.resetPassword(
                                email: e,
                                token: t,
                                newPassword: p
                            ) ?? "Password updated. You can log in now."
                        }
                    }
                    .disabled(
                        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        newPass.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                
                if !info.isEmpty {
                    Text(info)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
