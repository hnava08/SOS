import Foundation
import LocalAuthentication
import Combine

@MainActor
final class AppLockStore: ObservableObject {
    static let shared = AppLockStore()

    @Published var biometricLockEnabled: Bool {
        didSet { UserDefaults.standard.set(biometricLockEnabled, forKey: Keys.enabled) }
    }

    /// Una vez desbloqueado en esta sesión de app, no vuelve a pedir hasta background largo.
    @Published private(set) var isUnlocked = false

    private enum Keys {
        static let enabled = "security.biometricLockEnabled.v1"
    }

    private init() {
        biometricLockEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)
        // Sin bloqueo activo, el contenido sensible es accesible.
        isUnlocked = !UserDefaults.standard.bool(forKey: Keys.enabled)
    }

    var biometryAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            || context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    var biometryLabel: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Código del iPhone"
        }
    }

    func lockIfNeeded() {
        if biometricLockEnabled {
            isUnlocked = false
        }
    }

    func unlock(reason: String) async -> Bool {
        guard biometricLockEnabled else {
            isUnlocked = true
            return true
        }

        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"
        var error: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        do {
            let ok = try await context.evaluatePolicy(policy, localizedReason: reason)
            isUnlocked = ok
            return ok
        } catch {
            isUnlocked = false
            return false
        }
    }

    func reset() {
        biometricLockEnabled = false
        isUnlocked = true
    }
}
