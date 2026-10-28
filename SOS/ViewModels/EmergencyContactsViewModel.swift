import Foundation
import UIKit
import Combine

@MainActor
final class EmergencyContactsViewModel: ObservableObject {
    @Published var profile: HealthProfile
    @Published var showAddContact = false
    @Published var contactToEdit: EmergencyContact?
    @Published var contactPendingCall: EmergencyContact?

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

    var contacts: [EmergencyContact] {
        profile.emergencyContacts.sorted { lhs, rhs in
            if lhs.isPrimary != rhs.isPrimary { return lhs.isPrimary && !rhs.isPrimary }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var primaryContact: EmergencyContact? {
        contacts.first(where: \.isPrimary) ?? contacts.first
    }

    var hasContacts: Bool {
        !contacts.isEmpty
    }

    func call(_ contact: EmergencyContact) {
        let digits = contact.phoneNumber.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    func message(_ contact: EmergencyContact) {
        let digits = contact.phoneNumber.filter { $0.isNumber || $0 == "+" }
        let body = "SOS Santa Cruz: necesito ayuda. Estoy en una emergencia médica."
        var components = URLComponents()
        components.scheme = "sms"
        components.path = digits
        components.queryItems = [URLQueryItem(name: "body", value: body)]
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    func save(_ contact: EmergencyContact, isNew: Bool) {
        if isNew {
            store.addContact(contact)
        } else {
            store.updateContact(contact)
        }
    }

    func delete(_ contact: EmergencyContact) {
        store.deleteContact(id: contact.id)
    }

    func makePrimary(_ contact: EmergencyContact) {
        var updated = contact
        updated.isPrimary = true
        store.updateContact(updated)
    }
}
