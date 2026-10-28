import Foundation
import CoreLocation

enum EmergencyType: String, CaseIterable, Identifiable, Hashable {
    case chestPain
    case accident
    case breathing
    case unconscious
    case bleeding
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chestPain: return "Dolor de pecho"
        case .accident: return "Accidente / trauma"
        case .breathing: return "Dificultad para respirar"
        case .unconscious: return "Persona inconsciente"
        case .bleeding: return "Sangrado grave"
        case .other: return "Otra emergencia"
        }
    }

    var subtitle: String {
        switch self {
        case .chestPain: return "Presión, opresión o dolor intenso"
        case .accident: return "Caídas, golpes o lesiones"
        case .breathing: return "Ahogo, asma o falta de aire"
        case .unconscious: return "No responde o está desvanecida"
        case .bleeding: return "Herida con sangrado abundante"
        case .other: return "Situación médica urgente"
        }
    }

    var icon: String {
        switch self {
        case .chestPain: return "heart.fill"
        case .accident: return "figure.fall"
        case .breathing: return "lungs.fill"
        case .unconscious: return "person.fill.questionmark"
        case .bleeding: return "drop.fill"
        case .other: return "cross.case.fill"
        }
    }

    var priorityLabel: String {
        switch self {
        case .chestPain, .unconscious, .breathing, .bleeding:
            return "Alta prioridad"
        case .accident, .other:
            return "Urgente"
        }
    }

    var statusMessage: String {
        "Ambulancia en camino · \(title)"
    }

    var firstAidTips: [FirstAidTip] {
        switch self {
        case .chestPain:
            return [
                FirstAidTip(
                    title: "Dolor de pecho",
                    steps: [
                        "Haz que la persona se siente y repose, sin caminar.",
                        "Afloja ropa ajustada alrededor del pecho y cuello.",
                        "Si tiene medicación cardíaca indicada por su médico y está consciente, sigue sus instrucciones.",
                        "No le des comida ni estimulantes. Mantén la calma hasta que llegue la ambulancia."
                    ],
                    icon: "heart.fill"
                )
            ]
        case .accident:
            return [
                FirstAidTip(
                    title: "Accidente o trauma",
                    steps: [
                        "No muevas a la persona si sospechas lesión de cuello o espalda, salvo peligro inmediato.",
                        "Controla sangrados con presión directa usando un paño limpio.",
                        "Mantén la zona despejada para la ambulancia.",
                        "Anota qué ocurrió y a qué hora para informar al personal."
                    ],
                    icon: "figure.fall"
                )
            ]
        case .breathing:
            return [
                FirstAidTip(
                    title: "Dificultad para respirar",
                    steps: [
                        "Siéntala erguida, ligeramente inclinada hacia adelante.",
                        "Abre ventanas o busca aire fresco.",
                        "Si usa inhalador prescrito, ayúdala a usarlo según indicación.",
                        "No la dejes sola. Observa si empeora la coloración de labios o uñas."
                    ],
                    icon: "lungs.fill"
                )
            ]
        case .unconscious:
            return [
                FirstAidTip(
                    title: "Persona inconsciente",
                    steps: [
                        "Verifica si responde y si respira.",
                        "Si respira, colócala en posición lateral de seguridad.",
                        "Si no respira, inicia RCP solo si sabes hacerlo y el operador te guía.",
                        "No le des líquidos ni medicamentos por la boca."
                    ],
                    icon: "person.fill.questionmark"
                )
            ]
        case .bleeding:
            return [
                FirstAidTip(
                    title: "Sangrado grave",
                    steps: [
                        "Aplica presión firme y continua sobre la herida con un paño limpio.",
                        "Si es posible, eleva la zona herida por encima del corazón.",
                        "No retires objetos clavados; inmovilízalos y espera ayuda.",
                        "Si el paño se empapa, añade otro encima sin quitar el anterior."
                    ],
                    icon: "drop.fill"
                )
            ]
        case .other:
            return FirstAidTip.samples
        }
    }
}

struct EmergencyRequest: Hashable {
    var type: EmergencyType
    var coordinate: CLLocationCoordinate2D
    var addressLabel: String
    var unitNumber: String
    var etaMinutes: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(addressLabel)
        hasher.combine(unitNumber)
        hasher.combine(etaMinutes)
    }

    static func == (lhs: EmergencyRequest, rhs: EmergencyRequest) -> Bool {
        lhs.type == rhs.type
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.addressLabel == rhs.addressLabel
            && lhs.unitNumber == rhs.unitNumber
            && lhs.etaMinutes == rhs.etaMinutes
    }
}
