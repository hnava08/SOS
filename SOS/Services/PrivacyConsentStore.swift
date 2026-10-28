import Foundation
import Combine

/// Consentimiento explícito de privacidad (versión de política + usos de datos médicos).
@MainActor
final class PrivacyConsentStore: ObservableObject {
    static let shared = PrivacyConsentStore()

    /// Sube este número cuando cambie materialmente la política.
    static let currentPolicyVersion = 2

    @Published private(set) var acceptedPolicyVersion: Int
    @Published private(set) var acceptedAt: Date?
    @Published var medicalShareConsent: Bool {
        didSet { defaults.set(medicalShareConsent, forKey: Keys.medicalShare) }
    }
    @Published var analyticsConsent: Bool {
        didSet {
            defaults.set(analyticsConsent, forKey: Keys.analyticsConsent)
            AppSettingsStore.shared.analyticsEnabled = analyticsConsent
        }
    }

    var needsConsent: Bool {
        acceptedPolicyVersion < Self.currentPolicyVersion
    }

    private enum Keys {
        static let policyVersion = "privacy.policyVersion.v1"
        static let acceptedAt = "privacy.acceptedAt.v1"
        static let medicalShare = "privacy.medicalShareConsent.v1"
        static let analyticsConsent = "privacy.analyticsConsent.v1"
    }

    private let defaults = UserDefaults.standard

    private init() {
        acceptedPolicyVersion = defaults.integer(forKey: Keys.policyVersion)
        if let ts = defaults.object(forKey: Keys.acceptedAt) as? Date {
            acceptedAt = ts
        } else if let interval = defaults.object(forKey: Keys.acceptedAt) as? TimeInterval {
            acceptedAt = Date(timeIntervalSince1970: interval)
        } else {
            acceptedAt = nil
        }
        medicalShareConsent = defaults.object(forKey: Keys.medicalShare) as? Bool ?? false
        analyticsConsent = defaults.object(forKey: Keys.analyticsConsent) as? Bool
            ?? AppSettingsStore.shared.analyticsEnabled
    }

    func acceptCurrentPolicy(medicalShare: Bool, analytics: Bool) {
        acceptedPolicyVersion = Self.currentPolicyVersion
        acceptedAt = Date()
        medicalShareConsent = medicalShare
        analyticsConsent = analytics

        defaults.set(acceptedPolicyVersion, forKey: Keys.policyVersion)
        defaults.set(acceptedAt, forKey: Keys.acceptedAt)

        AppSettingsStore.shared.shareHealthProfileWithDispatch = medicalShare
        AppSettingsStore.shared.analyticsEnabled = analytics
    }

    func revokeMedicalShare() {
        medicalShareConsent = false
        AppSettingsStore.shared.shareHealthProfileWithDispatch = false
    }

    func reset() {
        acceptedPolicyVersion = 0
        acceptedAt = nil
        medicalShareConsent = false
        analyticsConsent = false
        defaults.removeObject(forKey: Keys.policyVersion)
        defaults.removeObject(forKey: Keys.acceptedAt)
        defaults.removeObject(forKey: Keys.medicalShare)
        defaults.removeObject(forKey: Keys.analyticsConsent)
        AppSettingsStore.shared.shareHealthProfileWithDispatch = false
        AppSettingsStore.shared.analyticsEnabled = false
    }
}
