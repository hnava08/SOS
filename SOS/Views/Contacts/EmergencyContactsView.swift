import SwiftUI

struct EmergencyContactsView: View {
    @StateObject private var viewModel = EmergencyContactsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                introCard

                if let primary = viewModel.primaryContact {
                    primaryCallCard(primary)
                }

                contactsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Contactos")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showAddContact = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Añadir contacto")
            }
        }
        .sheet(isPresented: $viewModel.showAddContact) {
            EditContactView { contact in
                viewModel.save(contact, isNew: true)
            }
        }
        .sheet(item: $viewModel.contactToEdit) { contact in
            EditContactView(
                existing: contact,
                onSave: { updated in
                    viewModel.save(updated, isNew: false)
                },
                onDelete: { deleted in
                    viewModel.delete(deleted)
                }
            )
        }
        .confirmationDialog(
            "Llamar a \(viewModel.contactPendingCall?.name ?? "contacto")",
            isPresented: Binding(
                get: { viewModel.contactPendingCall != nil },
                set: { if !$0 { viewModel.contactPendingCall = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let contact = viewModel.contactPendingCall {
                Button("Llamar \(contact.phoneNumber)") {
                    viewModel.call(contact)
                    viewModel.contactPendingCall = nil
                }
                Button("Enviar SMS") {
                    viewModel.message(contact)
                    viewModel.contactPendingCall = nil
                }
                Button("Cancelar", role: .cancel) {
                    viewModel.contactPendingCall = nil
                }
            }
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Acceso rápido en emergencia", systemImage: "bolt.heart.fill")
                .font(.headline)
                .foregroundStyle(SOSTheme.primaryRed)
            Text("Guarda familiares o personas de confianza. El contacto principal se prioriza cuando pides una ambulancia.")
                .font(.subheadline)
                .foregroundStyle(SOSTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
    }

    private func primaryCallCard(_ contact: EmergencyContact) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Contacto principal")
                .font(.caption.weight(.bold))
                .foregroundStyle(SOSTheme.secondaryText)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SOSTheme.headerGradient)
                        .frame(width: 52, height: 52)
                    Text(initials(for: contact.name))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.title3.weight(.bold))
                    Text("\(contact.relationship) · \(contact.phoneNumber)")
                        .font(.caption)
                        .foregroundStyle(SOSTheme.secondaryText)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.call(contact)
                } label: {
                    Label("Llamar ahora", systemImage: "phone.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SOSTheme.headerGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.message(contact)
                } label: {
                    Image(systemName: "message.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SOSTheme.primaryRed)
                        .frame(width: 48, height: 48)
                        .background(SOSTheme.lightRed)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Enviar SMS")
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 8, y: 3)
    }

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Todos los contactos")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.contacts.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SOSTheme.lightRed)
                    .clipShape(Capsule())
            }

            if !viewModel.hasContacts {
                emptyState
            } else {
                ForEach(viewModel.contacts) { contact in
                    contactRow(contact)
                }
            }

            Button {
                viewModel.showAddContact = true
            } label: {
                Label("Añadir contacto", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SOSTheme.lightRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(SOSTheme.primaryRed)
            Text("Sin contactos todavía")
                .font(.subheadline.weight(.semibold))
            Text("Añade al menos un familiar para avisar en una emergencia.")
                .font(.caption)
                .foregroundStyle(SOSTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func contactRow(_ contact: EmergencyContact) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SOSTheme.lightRed)
                        .frame(width: 42, height: 42)
                    Text(initials(for: contact.name))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SOSTheme.primaryRed)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(contact.name)
                            .font(.subheadline.weight(.semibold))
                        if contact.isPrimary {
                            Text("Principal")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SOSTheme.primaryRed)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(contact.relationship) · \(contact.phoneNumber)")
                        .font(.caption)
                        .foregroundStyle(SOSTheme.secondaryText)
                }

                Spacer()

                Button {
                    viewModel.contactPendingCall = contact
                } label: {
                    Image(systemName: "phone.circle.fill")
                        .font(.title)
                        .foregroundStyle(SOSTheme.primaryRed)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                if !contact.isPrimary {
                    Button {
                        viewModel.makePrimary(contact)
                    } label: {
                        Label("Hacer principal", systemImage: "star")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(SOSTheme.primaryRed)
                }

                Button {
                    viewModel.contactToEdit = contact
                } label: {
                    Label("Editar", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased().isEmpty ? "?" : letters.joined().uppercased()
    }
}

#Preview {
    NavigationStack {
        EmergencyContactsView()
    }
}
