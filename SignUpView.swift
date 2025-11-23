import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var appSession: AppSession
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var fullName = ""
    @State private var idNumber = ""
    @State private var phone = ""
    @State private var emergencyContact = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    
    @State private var info = ""
    @State private var showVerify = false
    @State private var pendingEmail = ""
    
    private var canSubmit: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !idNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !emergencyContact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        password == confirm
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $fullName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("ID Number (IC/Passport)", text: $idNumber)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                    
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("Emergency Contact", text: $emergencyContact)
                        .keyboardType(.phonePad)
                }
                
                Section("Account") {
                    TextField("Email (for login & verification)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirm)
                }
                
                if !info.isEmpty {
                    Text(info)
                        .foregroundStyle(.secondary)
                }
                
                Button("Sign Up") {
                    Task {
                        let n   = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let idn = idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                        let ph  = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                        let emg = emergencyContact.trimmingCharacters(in: .whitespacesAndNewlines)
                        let e   = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        let p   = password.trimmingCharacters(in: .whitespacesAndNewlines)
                        let c   = confirm.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard p == c else {
                            info = "Passwords do not match."
                            return
                        }
                        
                        if let err = await appSession.signUpTenant(
                            email: e,
                            password: p,
                            name: n,
                            phone: ph,
                            idNumber: idn,
                            emergency: emg
                        ) {
                            info = err
                            return
                        }
                        
                        // Save tenant locally in AppStore (for demo)
                        var t = Tenant(name: n)
                        t.email = e
                        t.phone = ph
                        t.idNumber = idn
                        t.emergencyContact = emg
                        store.tenants.append(t)
                        
                        pendingEmail = e
                        showVerify = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
            .navigationTitle("Sign Up")
            .sheet(isPresented: $showVerify) {
                VerifyEmailSheet(email: pendingEmail) {
                    Task {
                        _ = await appSession.login(email: pendingEmail, password: password)
                        dismiss()
                    }
                }
            }
        }
    }
}
