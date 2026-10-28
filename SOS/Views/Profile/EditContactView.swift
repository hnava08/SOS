import SwiftUI

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss

    let existing: EmergencyContact?
    let onSave: (EmergencyContact) -> Void
    let onDelete: ((EmergencyContact) -> Void)?

    @State private var name: String
    @State private var relationship: String
    @State private var phoneNumber: String
    @State private var isPrimary: Bool
    @State private var showDeleteConfirm = false

    private let relationships = ["Esposa", "Esposo", "Madre", "Padre", "Hermano", "Hermana", "Hijo", "Hija", "Amigo", "Otro"]

    init(
        existing: EmergencyContact? = nil,
        onSave: @escaping (EmergencyContact) -> Void,
        onDelete: ((EmergencyContact) -> Void)? = nil
    ) {
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: existing?.name ?? "")
        _relationship = State(initialValue: existing?.relationship ?? "Familiar")
        _phoneNumber = State(initialValue: existing?.phoneNumber ?? "+591 ")
        _isPrimary = State(initialValue: existing?.isPrimary ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del contacto") {
                    TextField("Nombre", text: $name)
                    Picker("Parentesco", selection: $relationship) {
                        ForEach(relationships, id: \.self) { item in
                            Text(item).tag(item)
                        }
                        if !relationships.contains(relationship) {
                            Text(relationship).tag(relationship)
                        }
                    }
                    TextField("Teléfono", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section {
                    Toggle("Contacto principal", isOn: $isPrimary)
                } footer: {
                    Text("El contacto principal aparece primero en emergencias.")
                }

                if existing != nil, onDelete != nil {
                    Section {
                        Button("Eliminar contacto", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "Nuevo contacto" : "Editar contacto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        let contact = EmergencyContact(
                            id: existing?.id ?? UUID(),
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            relationship: relationship,
                            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                            isPrimary: isPrimary
                        )
                        onSave(contact)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "¿Eliminar este contacto?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    if let existing {
                        onDelete?(existing)
                    }
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && phoneNumber.filter(\.isNumber).count >= 7
    }
}

#Preview {
    EditContactView(onSave: { _ in })
}
