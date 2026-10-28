import SwiftUI

struct EditCriticalInfoView: View {
    @Environment(\.dismiss) private var dismiss

    let initialName: String
    let initialBloodType: String
    let initialAllergies: [String]
    let initialMedications: [String]
    let initialConditions: [String]
    let onSave: (String, String, [String], [String], [String]) -> Void

    @State private var fullName: String
    @State private var bloodType: String
    @State private var allergies: [String]
    @State private var medications: [String]
    @State private var conditions: [String]
    @State private var allergyDraft = ""
    @State private var medicationDraft = ""
    @State private var conditionDraft = ""

    init(
        initialName: String,
        initialBloodType: String,
        initialAllergies: [String],
        initialMedications: [String],
        initialConditions: [String],
        onSave: @escaping (String, String, [String], [String], [String]) -> Void
    ) {
        self.initialName = initialName
        self.initialBloodType = initialBloodType
        self.initialAllergies = initialAllergies
        self.initialMedications = initialMedications
        self.initialConditions = initialConditions
        self.onSave = onSave
        _fullName = State(initialValue: initialName)
        _bloodType = State(initialValue: initialBloodType)
        _allergies = State(initialValue: initialAllergies)
        _medications = State(initialValue: initialMedications)
        _conditions = State(initialValue: initialConditions)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identificación") {
                    TextField("Nombre completo", text: $fullName)
                }

                Section("Grupo sanguíneo") {
                    Picker("Grupo sanguíneo", selection: $bloodType) {
                        ForEach(BloodTypeOption.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 120)
                }

                tagSection(
                    title: "Alergias",
                    items: $allergies,
                    draft: $allergyDraft,
                    placeholder: "Ej. Penicilina"
                )

                tagSection(
                    title: "Medicamentos actuales",
                    items: $medications,
                    draft: $medicationDraft,
                    placeholder: "Ej. Ibuprofeno"
                )

                tagSection(
                    title: "Condiciones médicas",
                    items: $conditions,
                    draft: $conditionDraft,
                    placeholder: "Ej. Asma, diabetes"
                )
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        onSave(
                            fullName,
                            bloodType,
                            cleaned(allergies),
                            cleaned(medications),
                            cleaned(conditions)
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func tagSection(
        title: String,
        items: Binding<[String]>,
        draft: Binding<String>,
        placeholder: String
    ) -> some View {
        Section(title) {
            ForEach(items.wrappedValue, id: \.self) { item in
                HStack {
                    Text(item)
                    Spacer()
                    Button(role: .destructive) {
                        items.wrappedValue.removeAll { $0 == item }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                TextField(placeholder, text: draft)
                Button("Añadir") {
                    let value = draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !value.isEmpty else { return }
                    if !items.wrappedValue.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
                        items.wrappedValue.append(value)
                    }
                    draft.wrappedValue = ""
                }
                .disabled(draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func cleaned(_ values: [String]) -> [String] {
        values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    EditCriticalInfoView(
        initialName: "Usuario SOS",
        initialBloodType: "O+",
        initialAllergies: ["Penicilina"],
        initialMedications: ["Ibuprofeno"],
        initialConditions: [],
        onSave: { _, _, _, _, _ in }
    )
}
