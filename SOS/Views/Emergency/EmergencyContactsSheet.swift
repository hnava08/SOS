import SwiftUI

struct EmergencyContactsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EmergencyContactsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasContacts {
                    List {
                        if let primary = viewModel.primaryContact {
                            Section("Llamada rápida") {
                                Button {
                                    viewModel.call(primary)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.fill")
                                            .foregroundStyle(.white)
                                            .frame(width: 40, height: 40)
                                            .background(SOSTheme.primaryRed)
                                            .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Llamar a \(primary.name)")
                                                .font(.body.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text("Contacto principal · \(primary.phoneNumber)")
                                                .font(.caption)
                                                .foregroundStyle(SOSTheme.secondaryText)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        Section("Todos") {
                            ForEach(viewModel.contacts) { contact in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(contact.name)
                                                .font(.body.weight(.semibold))
                                            if contact.isPrimary {
                                                Text("Principal")
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundStyle(SOSTheme.primaryRed)
                                            }
                                        }
                                        Text("\(contact.relationship) · \(contact.phoneNumber)")
                                            .font(.caption)
                                            .foregroundStyle(SOSTheme.secondaryText)
                                    }

                                    Spacer()

                                    Button {
                                        viewModel.message(contact)
                                    } label: {
                                        Image(systemName: "message.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(SOSTheme.secondaryText)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        viewModel.call(contact)
                                    } label: {
                                        Image(systemName: "phone.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(SOSTheme.primaryRed)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Sin contactos",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text("Añade familiares desde el menú Contactos de emergencia.")
                    )
                }
            }
            .navigationTitle("Familia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    EmergencyContactsSheet()
}
