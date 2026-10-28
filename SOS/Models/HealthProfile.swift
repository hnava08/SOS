import Foundation

struct HealthProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var fullName: String
    var bloodType: String
    var allergies: [String]
    var medications: [String]
    var conditions: [String]
    var emergencyContacts: [EmergencyContact]
    var waitingInstructions: [WaitingInstruction]

    var allergiesDisplay: String {
        allergies.isEmpty ? "Ninguna registrada" : allergies.joined(separator: ", ")
    }

    var medicationsDisplay: String {
        medications.isEmpty ? "Ninguno registrado" : medications.joined(separator: ", ")
    }

    var conditionsDisplay: String {
        conditions.isEmpty ? "Ninguna registrada" : conditions.joined(separator: ", ")
    }
}

struct EmergencyContact: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var relationship: String
    var phoneNumber: String
    var isPrimary: Bool

    init(
        id: UUID = UUID(),
        name: String,
        relationship: String,
        phoneNumber: String,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.phoneNumber = phoneNumber
        self.isPrimary = isPrimary
    }
}

struct WaitingInstruction: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var icon: String

    init(id: UUID = UUID(), title: String, detail: String, icon: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.icon = icon
    }
}

enum BloodTypeOption: String, CaseIterable, Identifiable {
    case oPositive = "O+"
    case oNegative = "O-"
    case aPositive = "A+"
    case aNegative = "A-"
    case bPositive = "B+"
    case bNegative = "B-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case unknown = "Desconocido"

    var id: String { rawValue }
}

extension HealthProfile {
    static let sample = HealthProfile(
        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
        fullName: "Usuario SOS",
        bloodType: "O+",
        allergies: ["Penicilina"],
        medications: ["Ibuprofeno"],
        conditions: [],
        emergencyContacts: [
            EmergencyContact(name: "María González", relationship: "Esposa", phoneNumber: "+591 70012345", isPrimary: true),
            EmergencyContact(name: "Carlos Mendoza", relationship: "Hermano", phoneNumber: "+591 70123456"),
            EmergencyContact(name: "Ana Ríos", relationship: "Madre", phoneNumber: "+591 70234567")
        ],
        waitingInstructions: [
            WaitingInstruction(
                title: "Mantén la calma",
                detail: "Respira profundo y permanece donde estás. La ayuda ya está en camino.",
                icon: "lungs.fill"
            ),
            WaitingInstruction(
                title: "Despeja el área",
                detail: "Asegura un espacio libre para que la ambulancia pueda acceder sin obstáculos.",
                icon: "figure.walk.motion"
            ),
            WaitingInstruction(
                title: "No muevas al paciente",
                detail: "A menos que haya peligro inmediato, evita mover a la persona lesionada.",
                icon: "hand.raised.fill"
            ),
            WaitingInstruction(
                title: "Ten tu perfil listo",
                detail: "Muestra tu grupo sanguíneo y alergias al personal médico al llegar.",
                icon: "doc.text.fill"
            )
        ]
    )
}
