import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case spanish = "es"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .spanish: return "es_BO"
        case .english: return "en_US"
        }
    }
}

@MainActor
final class AppSettingsStore: ObservableObject {
    static let shared = AppSettingsStore()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    @Published var shareLocationInEmergency: Bool {
        didSet { UserDefaults.standard.set(shareLocationInEmergency, forKey: Keys.shareLocation) }
    }

    @Published var shareHealthProfileWithDispatch: Bool {
        didSet { UserDefaults.standard.set(shareHealthProfileWithDispatch, forKey: Keys.shareHealth) }
    }

    @Published var keepEmergencyHistory: Bool {
        didSet { UserDefaults.standard.set(keepEmergencyHistory, forKey: Keys.keepHistory) }
    }

    @Published var analyticsEnabled: Bool {
        didSet { UserDefaults.standard.set(analyticsEnabled, forKey: Keys.analytics) }
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private enum Keys {
        static let language = "appLanguage"
        static let shareLocation = "shareLocationAlways"
        static let shareHealth = "shareHealthProfileWithDispatch"
        static let keepHistory = "keepEmergencyHistory"
        static let analytics = "analyticsEnabled"
    }

    private init() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: Keys.language),
           let language = AppLanguage(rawValue: raw) {
            self.language = language
        } else {
            self.language = .spanish
        }
        shareLocationInEmergency = defaults.object(forKey: Keys.shareLocation) as? Bool ?? true
        shareHealthProfileWithDispatch = defaults.object(forKey: Keys.shareHealth) as? Bool ?? true
        keepEmergencyHistory = defaults.object(forKey: Keys.keepHistory) as? Bool ?? true
        analyticsEnabled = defaults.object(forKey: Keys.analytics) as? Bool ?? false
    }

    func t(_ es: String, _ en: String) -> String {
        language == .spanish ? es : en
    }

    func clearLocalSensitiveData() {
        HealthProfileStore.shared.eraseSecureStorage()
        EmergencyHistoryStore.shared.clearAll()
        PrivacyConsentStore.shared.reset()
        AppLockStore.shared.reset()
    }
}
