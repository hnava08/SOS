import SwiftUI

struct HealthProfileView: View {
    @StateObject private var viewModel = HealthProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                criticalInfoSection
                emergencyContactsSection
                waitingGuideSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Perfil de Salud")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") {
                    viewModel.showEditCritical = true
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $viewModel.showEditCritical) {
            EditCriticalInfoView(
                initialName: viewModel.profile.fullName,
                initialBloodType: viewModel.profile.bloodType,
                initialAllergies: viewModel.profile.allergies,
                initialMedications: viewModel.profile.medications,
                initialConditions: viewModel.profile.conditions
            ) { name, blood, allergies, meds, conditions in
                viewModel.saveCriticalInfo(
                    fullName: name,
                    bloodType: blood,
                    allergies: allergies,
                    medications: meds,
                    conditions: conditions
                )
            }
        }
        .sheet(isPresented: $viewModel.showAddContact) {
            EditContactView { contact in
                viewModel.saveContact(contact, isNew: true)
            }
        }
        .sheet(item: $viewModel.contactToEdit) { contact in
            EditContactView(
                existing: contact,
                onSave: { updated in
                    viewModel.saveContact(updated, isNew: false)
                },
                onDelete: { deleted in
                    viewModel.deleteContact(deleted)
                }
            )
        }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(SOSTheme.headerGradient)
                    .frame(width: 56, height: 56)
                Text(initials)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.profile.fullName)
                    .font(.title3.weight(.bold))
                Text("Visible para personal de emergencia")
                    .font(.subheadline)
                    .foregroundStyle(SOSTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "shield.checkered")
                .font(.title2)
                .foregroundStyle(SOSTheme.primaryRed)
        }
        .padding(.top, 8)
    }

    private var criticalInfoSection: some View {
        VStack(spacing: 12) {
            CriticalInfoBlock(
                title: "Grupo Sanguíneo",
                value: viewModel.profile.bloodType,
                icon: "drop.fill"
            )
            CriticalInfoBlock(
                title: "Alergias",
                value: viewModel.profile.allergiesDisplay,
                icon: "allergens"
            )
            CriticalInfoBlock(
                title: "Medicamentos Actuales",
                value: viewModel.profile.medicationsDisplay,
                icon: "pills.fill"
            )
            CriticalInfoBlock(
                title: "Condiciones Médicas",
                value: viewModel.profile.conditionsDisplay,
                icon: "stethoscope"
            )

            Button {
                viewModel.showEditCritical = true
            } label: {
                Label("Editar información crítica", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(SOSTheme.lightRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Contactos de Emergencia", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(SOSTheme.primaryRed)
                Spacer()
                Button {
                    viewModel.showAddContact = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(SOSTheme.primaryRed)
                }
                .accessibilityLabel("Añadir contacto")
            }

            if viewModel.sortedContacts.isEmpty {
                Text("No hay contactos. Añade al menos uno.")
                    .font(.subheadline)
                    .foregroundStyle(SOSTheme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.sortedContacts) { contact in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
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
                            viewModel.contactToEdit = contact
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundStyle(SOSTheme.secondaryText)
                        }

                        Button {
                            viewModel.callContact(contact)
                        } label: {
                            Image(systemName: "phone.circle.fill")
                                .font(.title)
                                .foregroundStyle(SOSTheme.primaryRed)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6).opacity(0.65))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: SOSTheme.shadow, radius: 8, y: 3)
        )
    }

    private var waitingGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Qué hacer mientras llega la ayuda", systemImage: "list.bullet.clipboard.fill")
                .font(.headline)
                .foregroundStyle(SOSTheme.primaryRed)

            ForEach(WaitingGuideContent.general().doSteps.prefix(4)) { step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: step.icon)
                        .font(.body)
                        .foregroundStyle(SOSTheme.primaryRed)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.subheadline.weight(.semibold))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(SOSTheme.secondaryText)
                    }
                }
                .padding(.vertical, 4)
            }

            NavigationLink {
                WaitingGuideView()
            } label: {
                Label("Ver guía completa", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(SOSTheme.lightRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: SOSTheme.shadow, radius: 8, y: 3)
        )
    }

    private var initials: String {
        let parts = viewModel.profile.fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased().isEmpty ? "SOS" : letters.joined().uppercased()
    }
}

#Preview {
    NavigationStack {
        HealthProfileView()
    }
}
