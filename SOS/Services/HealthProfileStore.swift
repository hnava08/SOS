import Foundation
import Combine

@MainActor
final class HealthProfileStore: ObservableObject {
    static let shared = HealthProfileStore()

    @Published private(set) var profile: HealthProfile

    private let storageKey = "sos.healthProfile.v1"
    private let keychainAccount = "healthProfile.v1"
    private let defaults: UserDefaults
    private var didHydrate = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Arranque rápido: perfil vacío en memoria. Keychain se hidrata en background.
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(HealthProfile.self, from: data) {
            self.profile = saved
        } else {
            self.profile = HealthProfile(
                id: UUID(),
                fullName: "",
                bloodType: "Desconocido",
                allergies: [],
                medications: [],
                conditions: [],
                emergencyContacts: [],
                waitingInstructions: []
            )
        }

        Task(priority: .utility) { await hydrateFromKeychainIfNeeded() }
    }

    private func hydrateFromKeychainIfNeeded() async {
        guard !didHydrate else { return }
        didHydrate = true

        let account = keychainAccount
        let data = await Task.detached(priority: .utility) {
            KeychainStore.readSecureData(account: account)
        }.value

        if let data,
           let saved = try? JSONDecoder().decode(HealthProfile.self, from: data) {
            profile = saved
            defaults.removeObject(forKey: storageKey)
            return
        }

        // Sin datos previos: usa sample y guárdalo fuera del hilo UI.
        profile = .sample
        let snapshot = profile
        await Task.detached(priority: .utility) {
            guard let encoded = try? JSONEncoder().encode(snapshot) else { return }
            try? KeychainStore.saveSecureData(encoded, account: account)
        }.value
        defaults.removeObject(forKey: storageKey)
    }

    func updateProfile(_ transform: (inout HealthProfile) -> Void) {
        transform(&profile)
        persist()
    }

    func save(_ newProfile: HealthProfile) {
        profile = newProfile
        persist()
    }

    func addContact(_ contact: EmergencyContact) {
        updateProfile { profile in
            var newContact = contact
            if newContact.isPrimary {
                for index in profile.emergencyContacts.indices {
                    profile.emergencyContacts[index].isPrimary = false
                }
            }
            profile.emergencyContacts.append(newContact)
        }
    }

    func updateContact(_ contact: EmergencyContact) {
        updateProfile { profile in
            guard let index = profile.emergencyContacts.firstIndex(where: { $0.id == contact.id }) else { return }
            var updated = contact
            if updated.isPrimary {
                for i in profile.emergencyContacts.indices where i != index {
                    profile.emergencyContacts[i].isPrimary = false
                }
            }
            profile.emergencyContacts[index] = updated
        }
    }

    func deleteContact(id: UUID) {
        updateProfile { profile in
            profile.emergencyContacts.removeAll { $0.id == id }
        }
    }

    func resetToSample() {
        profile = .sample
        persist()
    }

    func eraseSecureStorage() {
        profile = HealthProfile(
            id: UUID(),
            fullName: "",
            bloodType: "Desconocido",
            allergies: [],
            medications: [],
            conditions: [],
            emergencyContacts: [],
            waitingInstructions: []
        )
        KeychainStore.deleteSecureData(account: keychainAccount)
        defaults.removeObject(forKey: storageKey)
    }

    private func persist() {
        let snapshot = profile
        let account = keychainAccount
        defaults.removeObject(forKey: storageKey)
        Task(priority: .utility) {
            await Task.detached(priority: .utility) {
                guard let data = try? JSONEncoder().encode(snapshot) else { return }
                try? KeychainStore.saveSecureData(data, account: account)
            }.value
        }
    }
}
