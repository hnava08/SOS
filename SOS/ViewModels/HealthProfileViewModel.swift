import Foundation
import UIKit
import Combine

@MainActor
final class HealthProfileViewModel: ObservableObject {
    @Published var profile: HealthProfile
    @Published var showEditCritical = false
    @Published var showAddContact = false
    @Published var contactToEdit: EmergencyContact?

    private let store: HealthProfileStore
    private var cancellables = Set<AnyCancellable>()

    init(store: HealthProfileStore = .shared) {
        self.store = store
        self.profile = store.profile

        store.$profile
            .receive(on: RunLoop.main)
            .sink { [weak self] updated in
                self?.profile = updated
            }
            .store(in: &cancellables)
    }

    var sortedContacts: [EmergencyContact] {
        profile.emergencyContacts.sorted { lhs, rhs in
            if lhs.isPrimary != rhs.isPrimary { return lhs.isPrimary && !rhs.isPrimary }
            return lhs.name < rhs.name
        }
    }

    func callContact(_ contact: EmergencyContact) {
        let digits = contact.phoneNumber.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)") {
            UIApplication.shared.open(url)
        }
    }

    func saveCriticalInfo(
        fullName: String,
        bloodType: String,
        allergies: [String],
        medications: [String],
        conditions: [String]
    ) {
        store.updateProfile { profile in
            profile.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.bloodType = bloodType
            profile.allergies = allergies
            profile.medications = medications
            profile.conditions = conditions
        }
    }

    func saveContact(_ contact: EmergencyContact, isNew: Bool) {
        if isNew {
            store.addContact(contact)
        } else {
            store.updateContact(contact)
        }
    }

    func deleteContact(_ contact: EmergencyContact) {
        store.deleteContact(id: contact.id)
    }
}
