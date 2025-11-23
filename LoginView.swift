import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: AppSession
    
    @State private var username = ""
    @State private var password = ""
    @State private var info = ""
    
    @State private var showSignUp = false
    @State private var showForgot = false
    @State private var showReset = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email / admin", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    SecureField("Password", text: $password)
                    
                    if !info.isEmpty {
                        Text(info)
                            .foregroundStyle(.red)
                    }
                    
                    Button("Login") {
                        Task {
                            let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
                            let p = password.trimmingCharacters(in: .whitespacesAndNewlines)
                            info = await session.login(email: u, password: p) ?? ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    
                    HStack {
                        Button("Forgot password?") { showForgot = true }
                        Spacer()
                        Button("Reset password") { showReset = true }
                    }
                } header: {
                    Text("SIGN IN")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Smart Tenant")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Up") { showSignUp = true }
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgot) {
                ForgotPasswordView(email: $username)
            }
        }
        .sheet(isPresented: $showReset) {
            ResetPasswordView(email: $username)
        }
    }
}
