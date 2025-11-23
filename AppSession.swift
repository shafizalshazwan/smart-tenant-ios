import Foundation

enum UserRole: String, Codable, Equatable {
    case admin
    case tenant
}

struct AppUser: Codable, Equatable, Identifiable {
    var id = UUID()
    var email: String
    var role: UserRole
}

private struct APIResponse: Decodable {
    let ok: Bool
    let message: String?
    let role: String?
    let isVerified: Bool?
}

@MainActor
final class AppSession: ObservableObject {
    @Published var currentUser: AppUser? = nil
    
    /// TODO: Replace this with your own deployed Apps Script URL
    private let api = URL(string: "https://script.google.com/macros/s/PASTE_YOUR_WEB_APP_URL_HERE/exec")!
    
    // MARK: - Public Auth Methods
    
    func signUpTenant(
        email: String,
        password: String,
        name: String,
        phone: String,
        idNumber: String,
        emergency: String
    ) async -> String? {
        await request(action: "signup", data: [
            "email": email,
            "password": password,
            "name": name,
            "phone": phone,
            "idNumber": idNumber,
            "emergencyContact": emergency
        ])
    }
    
    func verifyEmail(email: String, code: String) async -> String? {
        await request(action: "verify", data: [
            "email": email,
            "code": code
        ])
    }
    
    func resendCode(email: String) async -> String? {
        await request(action: "resend", data: [
            "email": email
        ])
    }
    
    func login(email: String, password: String) async -> String? {
        if let msg = await request(action: "login", data: [
            "email": email,
            "password": password
        ]) {
            // server returned error message
            return msg
        }
        return nil
    }
    
    func forgotPassword(email: String) async -> String? {
        await request(action: "forgot", data: [
            "email": email
        ])
    }
    
    func resetPassword(email: String, token: String, newPassword: String) async -> String? {
        await request(action: "reset", data: [
            "email": email,
            "token": token,
            "newPassword": newPassword
        ])
    }
    
    func logout() {
        currentUser = nil
    }
    
    // MARK: - Low-level request helper
    
    private func request(action: String, data: [String: String]) async -> String? {
        var req = URLRequest(url: api)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = ["action": action]
        for (k, v) in data {
            payload[k] = v
        }
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (raw, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let rawText = String(data: raw, encoding: .utf8) ?? "<non-utf8>"
            print("🛰 [\(action)] HTTP \(status) raw:\n\(rawText)")
            
            let res = try JSONDecoder().decode(APIResponse.self, from: raw)
            
            if action == "login",
               res.ok,
               let email = data["email"],
               let roleStr = res.role,
               let role = UserRole(rawValue: roleStr) {
                self.currentUser = AppUser(email: email.lowercased(), role: role)
                return nil
            }
            
            return res.ok ? nil : (res.message ?? "Request failed")
        } catch {
            return "Decode/network error on \(action): \(error.localizedDescription)"
        }
    }
}
