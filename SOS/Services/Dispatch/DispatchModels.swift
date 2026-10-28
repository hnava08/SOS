import Foundation
import CoreLocation

struct DispatchTicket: Identifiable, Codable, Equatable {
    var id: String
    var unitNumber: String
    var etaMinutes: Int
    var status: String
    var emergencyType: String
    var addressLabel: String
    var latitude: Double
    var longitude: Double
    var ambulanceLatitude: Double
    var ambulanceLongitude: Double
    var route: [DispatchCoordinate]
    var createdAt: Date
}

struct DispatchCoordinate: Codable, Equatable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct DispatchAmbulance: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var unitNumber: String
    var callSign: String
    var baseName: String
    var hospital: String
    var level: String
    var equipment: String
    var crewSize: Int
    var status: String
    var latitude: Double
    var longitude: Double
    var distanceKm: Double
    var etaMinutes: Int

    var isAvailable: Bool { status == "available" }

    var levelLabel: String {
        level.lowercased().contains("avanz") ? "Soporte avanzado" : "Soporte básico"
    }
}

struct AmbulancesResponse: Codable {
    var ambulances: [DispatchAmbulance]
}

enum AmbulanceAssignmentMode: String, Codable {
    case closest
    case manual
}

struct DispatchChatMessageDTO: Identifiable, Codable, Equatable {
    var id: String
    var text: String
    var isFromUser: Bool
    var createdAt: Date
}

struct CreateDispatchRequest: Codable {
    var emergencyType: String
    var addressLabel: String
    var latitude: Double
    var longitude: Double
    var userName: String?
    var bloodType: String?
    var allergies: [String]?
    var medications: [String]?
    var shareHealthProfile: Bool
    var assignmentMode: AmbulanceAssignmentMode
    var ambulanceId: String?
}

enum DispatchServiceError: LocalizedError {
    case notConfigured
    case invalidResponse
    case server(message: String)
    case network(underlying: Error)
    case decoding
    case offline

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "No hay servidor de despacho configurado."
        case .invalidResponse:
            return "Respuesta inválida del despacho."
        case .server(let message):
            return message
        case .network(let underlying):
            return "Sin conexión con despacho: \(underlying.localizedDescription)"
        case .decoding:
            return "No se pudo interpretar la respuesta del despacho."
        case .offline:
            return "Sin internet. Llama al 911 para pedir una ambulancia."
        }
    }
}

protocol DispatchService: AnyObject, Sendable {
    func fetchAmbulances(latitude: Double, longitude: Double) async throws -> [DispatchAmbulance]
    func createEmergency(_ request: CreateDispatchRequest) async throws -> DispatchTicket
    func fetchTicket(id: String) async throws -> DispatchTicket
    func sendChatMessage(ticketId: String, text: String) async throws -> DispatchChatMessageDTO
    func fetchChat(ticketId: String) async throws -> [DispatchChatMessageDTO]
}
