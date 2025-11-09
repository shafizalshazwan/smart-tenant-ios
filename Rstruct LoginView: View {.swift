Rstruct LoginView: View {
    @EnvironmentObject private var session: AppSession
    @State private var username = ""
    @State private var password = ""
    @State private var info = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Smart Tenant").font(.largeTitle).bold()

            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if !info.isEmpty { Text(info).foregroundStyle(.red) }

            Button("Login") {
                let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
                let p = password.trimmingCharacters(in: .whitespacesAndNewlines)
                if !session.login(username: u, password: p) {
                    info = "Invalid credentials"
                } else {
                    info = ""
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding(20)
    }
}