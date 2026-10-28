import Foundation
import CoreLocation

enum EmergencyOutcome: String, Codable, CaseIterable {
    case dispatched
    case arrived
    case cancelled

    var title: String {
        switch self {
        case .dispatched: return "Despachada"
        case .arrived: return "Unidad llegó"
        case .cancelled: return "Cancelada"
        }
    }

    var colorName: String {
        switch self {
        case .dispatched: return "orange"
        case .arrived: return "green"
        case .cancelled: return "gray"
        }
    }
}

struct EmergencyHistoryRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var emergencyTypeRaw: String
    var emergencyTitle: String
    var unitNumber: String
    var etaMinutes: Int
    var addressLabel: String
    var latitude: Double
    var longitude: Double
    var outcome: EmergencyOutcome

    var emergencyType: EmergencyType? {
        EmergencyType(rawValue: emergencyTypeRaw)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
