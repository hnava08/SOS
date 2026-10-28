import Foundation
import Combine
import AuthenticationServices

enum AuthProvider: String, Codable, CaseIterable {
    case email
    case apple
    case google
    case phone

    var title: String {
        switch self {
        case .email: return "Correo"
        case .apple: return "Apple"
        case .google: return "Google"
        case .phone: return "Celular"
        }
    }
}

struct UserAccount: Codable, Equatable {
    var id: UUID
    var fullName: String
    var email: String
    var phone: String
    var provider: AuthProvider
    var providerSubject: String
    var createdAt: Date
    var lastSignInAt: Date?
    var syncEnabled: Bool
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailInUse
    case weakPassword
    case notSignedIn
    case keychainFailure
    case cancelled
    case phoneInvalid
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Correo o contraseña incorrectos."
        case .emailInUse: return "Ya existe una cuenta con ese correo."
        case .weakPassword: return "La contraseña debe tener al menos 6 caracteres."
        case .notSignedIn: return "No hay sesión activa."
        case .keychainFailure: return "No se pudo guardar la contraseña de forma segura."
        case .cancelled: return "Inicio de sesión cancelado."
        case .phoneInvalid: return "Ingresa un celular válido."
        case .network(let message): return message
        }
    }
}

@MainActor
final class AuthStore: ObservableObject {
    static let shared = AuthStore()

    @Published private(set) var currentUser: UserAccount?
    @Published private(set) var isSyncing = false
    @Published var lastSyncMessage: String = "Perfil guardado solo en este iPhone"
    @Published var lastError: String?

    var isSignedIn: Bool { currentUser != nil }

    /// Cuenta obligatoria: sin sesión no se entra al Home.
    var needsAccountPrompt: Bool { !isSignedIn }

    private let accountsKey = "sos.auth.accounts.v2"
    private let sessionKey = "sos.auth.sessionUserId.v1"
    private let defaults = UserDefaults.standard

    private init() {
        migrateAccountsIfNeeded()
        restoreSession()
    }

    func register(fullName: String, email: String, phone: String, password: String) throws {
        let normalizedEmail = normalize(email)
        guard password.count >= 6 else { throw AuthError.weakPassword }

        var accounts = loadAccounts()
        if accounts.contains(where: { normalize($0.email) == normalizedEmail }) {
            throw AuthError.emailInUse
        }

        let user = UserAccount(
            id: UUID(),
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: normalizedEmail,
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            provider: .email,
            providerSubject: normalizedEmail,
            createdAt: Date(),
            lastSignInAt: Date(),
            syncEnabled: false
        )

        try KeychainStore.savePassword(password, account: normalizedEmail)
        accounts.append(user)
        saveAccounts(accounts)
        finishSignIn(user, message: "Cuenta creada con correo")
    }

    func signIn(email: String, password: String) throws {
        let normalizedEmail = normalize(email)
        let accounts = loadAccounts()
        guard let user = accounts.first(where: {
            $0.provider == .email && normalize($0.email) == normalizedEmail
        }) else {
            throw AuthError.invalidCredentials
        }
        let stored = try KeychainStore.readPassword(account: normalizedEmail)
        guard stored == password else { throw AuthError.invalidCredentials }

        var updated = user
        updated.lastSignInAt = Date()
        upsert(updated)
        finishSignIn(updated, message: "Sesión iniciada con correo")
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) throws {
        let subject = credential.user
        let email = credential.email ?? "\(subject.prefix(8))@privaterelay.appleid.com"
        let given = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let fullName = given.isEmpty ? "Usuario Apple" : given

        let user = upsertProviderUser(
            provider: .apple,
            subject: subject,
            fullName: fullName,
            email: email,
            phone: ""
        )
        finishSignIn(user, message: "Sesión con Apple")
    }

    func signInWithGoogle(email: String, fullName: String) throws {
        let normalized = normalize(email)
        guard normalized.contains("@"), normalized.contains(".") else {
            throw AuthError.invalidCredentials
        }
        let user = upsertProviderUser(
            provider: .google,
            subject: normalized,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? normalized.split(separator: "@").first.map(String.init) ?? "Usuario Google"
                : fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: normalized,
            phone: ""
        )
        finishSignIn(user, message: "Sesión con Google")
    }

    func requestPhoneCode(phone: String) async throws -> String? {
        let normalized = normalizePhone(phone)
        guard normalized.count >= 8 else { throw AuthError.phoneInvalid }
        guard let serviceURL = DispatchServerConfig.baseURL,
              let url = URL(string: "v1/auth/phone/request", relativeTo: serviceURL) else {
            throw AuthError.network("Servidor de despacho no configurado.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(DispatchServerConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(["phone": normalized])
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.network("Sin respuesta del servidor.")
        }
        if !(200...299).contains(http.statusCode) {
            if let err = try? JSONDecoder().decode(ServerMessage.self, from: data) {
                throw AuthError.network(err.message)
            }
            throw AuthError.network("No se pudo enviar el código.")
        }
        let payload = try JSONDecoder().decode(PhoneOTPResponse.self, from: data)
        return payload.debugCode
    }

    func verifyPhoneCode(phone: String, code: String) async throws {
        let normalized = normalizePhone(phone)
        guard let serviceURL = DispatchServerConfig.baseURL,
              let url = URL(string: "v1/auth/phone/verify", relativeTo: serviceURL) else {
            throw AuthError.network("Servidor de despacho no configurado.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(DispatchServerConfig.apiKey)", forHTTPHeaderField: "Authorization")
        struct Body: Encodable { let phone: String; let code: String }
        request.httpBody = try JSONEncoder().encode(Body(phone: normalized, code: code))
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.network("Sin respuesta del servidor.")
        }
        if !(200...299).contains(http.statusCode) {
            if let err = try? JSONDecoder().decode(ServerMessage.self, from: data) {
                throw AuthError.network(err.message)
            }
            throw AuthError.network("Código incorrecto.")
        }
        let remote = try JSONDecoder().decode(PhoneAuthUserDTO.self, from: data)
        let user = upsertProviderUser(
            provider: .phone,
            subject: normalized,
            fullName: remote.fullName,
            email: remote.email ?? "",
            phone: remote.phone ?? normalized
        )
        finishSignIn(user, message: "Sesión con celular")
    }

    func signOut() {
        defaults.removeObject(forKey: sessionKey)
        currentUser = nil
        lastSyncMessage = "Sesión cerrada"
        lastError = nil
    }

    func updateProfile(fullName: String, phone: String) throws {
        guard var user = currentUser else { throw AuthError.notSignedIn }
        user.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        user.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        upsert(user)
        setSession(user)
        HealthProfileStore.shared.updateProfile { profile in
            profile.fullName = user.fullName
        }
    }

    func setCloudSyncEnabled(_ enabled: Bool) {
        guard var user = currentUser else { return }
        user.syncEnabled = enabled
        upsert(user)
        setSession(user)
        lastSyncMessage = enabled
            ? "Sincronización preparada · requiere backend en producción"
            : "Sincronización desactivada · solo este iPhone"
    }

    func deleteAccount(password: String? = nil, eraseMedicalData: Bool = true) throws {
        guard let user = currentUser else { throw AuthError.notSignedIn }

        if user.provider == .email {
            guard let password else { throw AuthError.invalidCredentials }
            let stored = try KeychainStore.readPassword(account: user.email)
            guard stored == password else { throw AuthError.invalidCredentials }
            KeychainStore.deletePassword(account: user.email)
        }

        var accounts = loadAccounts()
        accounts.removeAll { $0.id == user.id }
        saveAccounts(accounts)
        signOut()

        if eraseMedicalData {
            AppSettingsStore.shared.clearLocalSensitiveData()
        }
        lastSyncMessage = "Cuenta eliminada de este dispositivo"
    }

    // MARK: - Private

    private func finishSignIn(_ user: UserAccount, message: String) {
        setSession(user)
        HealthProfileStore.shared.updateProfile { profile in
            if profile.fullName.isEmpty || profile.fullName == "Usuario SOS" {
                profile.fullName = user.fullName
            }
        }
        lastSyncMessage = message
        lastError = nil
    }

    private func upsertProviderUser(
        provider: AuthProvider,
        subject: String,
        fullName: String,
        email: String,
        phone: String
    ) -> UserAccount {
        var accounts = loadAccounts()
        if let index = accounts.firstIndex(where: {
            $0.provider == provider && $0.providerSubject == subject
        }) {
            accounts[index].fullName = fullName.isEmpty ? accounts[index].fullName : fullName
            if !email.isEmpty { accounts[index].email = email }
            if !phone.isEmpty { accounts[index].phone = phone }
            accounts[index].lastSignInAt = Date()
            saveAccounts(accounts)
            return accounts[index]
        }

        let user = UserAccount(
            id: UUID(),
            fullName: fullName,
            email: email,
            phone: phone,
            provider: provider,
            providerSubject: subject,
            createdAt: Date(),
            lastSignInAt: Date(),
            syncEnabled: false
        )
        accounts.append(user)
        saveAccounts(accounts)
        return user
    }

    private func restoreSession() {
        guard let idString = defaults.string(forKey: sessionKey),
              let id = UUID(uuidString: idString),
              let user = loadAccounts().first(where: { $0.id == id }) else {
            currentUser = nil
            return
        }
        currentUser = user
    }

    private func setSession(_ user: UserAccount) {
        currentUser = user
        defaults.set(user.id.uuidString, forKey: sessionKey)
    }

    private func upsert(_ user: UserAccount) {
        var accounts = loadAccounts()
        if let index = accounts.firstIndex(where: { $0.id == user.id }) {
            accounts[index] = user
        } else {
            accounts.append(user)
        }
        saveAccounts(accounts)
    }

    private func loadAccounts() -> [UserAccount] {
        guard let data = defaults.data(forKey: accountsKey),
              let accounts = try? JSONDecoder().decode([UserAccount].self, from: data) else {
            return []
        }
        return accounts
    }

    private func saveAccounts(_ accounts: [UserAccount]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        defaults.set(data, forKey: accountsKey)
    }

    private func migrateAccountsIfNeeded() {
        let legacyKey = "sos.auth.accounts.v1"
        guard defaults.data(forKey: accountsKey) == nil,
              let data = defaults.data(forKey: legacyKey),
              let legacy = try? JSONDecoder().decode([LegacyAccount].self, from: data) else {
            return
        }
        let migrated: [UserAccount] = legacy.map { old in
            UserAccount(
                id: old.id,
                fullName: old.fullName,
                email: old.email,
                phone: old.phone,
                provider: .email,
                providerSubject: old.email.lowercased(),
                createdAt: old.createdAt,
                lastSignInAt: old.lastSignInAt,
                syncEnabled: old.syncEnabled
            )
        }
        saveAccounts(migrated)
        defaults.removeObject(forKey: legacyKey)
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizePhone(_ phone: String) -> String {
        phone.filter { $0.isNumber || $0 == "+" }
    }
}

private struct LegacyAccount: Codable {
    var id: UUID
    var fullName: String
    var email: String
    var phone: String
    var createdAt: Date
    var lastSignInAt: Date?
    var syncEnabled: Bool
}

private struct ServerMessage: Codable { var message: String }
private struct PhoneOTPResponse: Codable {
    var ok: Bool
    var message: String
    var expiresInSeconds: Int?
    var debugCode: String?
}
private struct PhoneAuthUserDTO: Codable {
    var id: String
    var provider: String
    var fullName: String
    var email: String?
    var phone: String?
}
