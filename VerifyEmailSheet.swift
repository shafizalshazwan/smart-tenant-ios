import SwiftUI

struct VerifyEmailSheet: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    
    let email: String
    var onVerified: () -> Void
    
    @State private var code = ""
    @State private var info = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("We emailed a 6-digit code to:")
                        .foregroundStyle(.secondary)
                    Text(email)
                        .font(.headline)
                    
                    TextField("6-digit code", text: $code)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    Button("Verify") {
                        Task {
                            let msg = await session.verifyEmail(email: email, code: code)
                            if msg == nil {
                                info = "Email verified ✅"
                                onVerified()
                                dismiss()
                            } else {
                                info = msg ?? "Verification failed."
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Resend code") {
                        Task {
                            let msg = await session.resendCode(email: email)
                            info = msg ?? "If the account exists, a new code was sent."
                        }
                    }
                    
                    if !info.isEmpty {
                        Text(info)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("VERIFY EMAIL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Verify")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
