import Foundation
import CoreLocation
import MapKit

enum TrackingPhase: String {
    case enCamino
    case cerca
    case llegando
    case llegada

    var title: String {
        switch self {
        case .enCamino: return "Ambulancia en camino"
        case .cerca: return "Unidad cerca de ti"
        case .llegando: return "Ambulancia llegando"
        case .llegada: return "Ambulancia en el lugar"
        }
    }

    var badge: String {
        switch self {
        case .enCamino: return "EN CAMINO"
        case .cerca: return "CERCA"
        case .llegando: return "LLEGANDO"
        case .llegada: return "LLEGÓ"
        }
    }
}

struct EmergencyStatus {
    var unitNumber: String
    var statusMessage: String
    var estimatedArrivalMinutes: Int
    var ambulanceCoordinate: CLLocationCoordinate2D
    var userCoordinate: CLLocationCoordinate2D
    var routeCoordinates: [CLLocationCoordinate2D]
    var landmarks: [Landmark]
    var phase: TrackingPhase = .enCamino
}

struct Landmark: Identifiable {
    let id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
    var icon: String
}

extension EmergencyStatus {
    static let santaCruzCenter = CLLocationCoordinate2D(latitude: -17.7833, longitude: -63.1821)

    static let sample = EmergencyStatus(
        unitNumber: "A-31",
        statusMessage: TrackingPhase.enCamino.title,
        estimatedArrivalMinutes: 8,
        ambulanceCoordinate: CLLocationCoordinate2D(latitude: -17.7650, longitude: -63.1950),
        userCoordinate: CLLocationCoordinate2D(latitude: -17.7833, longitude: -63.1821),
        routeCoordinates: [
            CLLocationCoordinate2D(latitude: -17.7650, longitude: -63.1950),
            CLLocationCoordinate2D(latitude: -17.7700, longitude: -63.1900),
            CLLocationCoordinate2D(latitude: -17.7760, longitude: -63.1860),
            CLLocationCoordinate2D(latitude: -17.7800, longitude: -63.1835),
            CLLocationCoordinate2D(latitude: -17.7833, longitude: -63.1821)
        ],
        landmarks: [
            Landmark(name: "Plaza 24 de Septiembre", coordinate: CLLocationCoordinate2D(latitude: -17.7836, longitude: -63.1811), icon: "building.columns.fill"),
            Landmark(name: "Catedral Metropolitana", coordinate: CLLocationCoordinate2D(latitude: -17.7839, longitude: -63.1805), icon: "cross.fill"),
            Landmark(name: "Av. Monseñor Rivero", coordinate: CLLocationCoordinate2D(latitude: -17.7780, longitude: -63.1840), icon: "road.lanes"),
            Landmark(name: "Equipetrol", coordinate: CLLocationCoordinate2D(latitude: -17.7610, longitude: -63.1780), icon: "building.2.fill")
        ],
        phase: .enCamino
    )
}

struct FirstAidTip: Identifiable {
    let id = UUID()
    var title: String
    var steps: [String]
    var icon: String
}

extension FirstAidTip {
    static let samples: [FirstAidTip] = [
        FirstAidTip(
            title: "Mientras esperas la ambulancia",
            steps: [
                "Evalúa si la persona responde y respira con normalidad.",
                "Colócala en posición lateral de seguridad si está inconsciente pero respira.",
                "Aplica presión directa sobre heridas sangrantes con un paño limpio.",
                "No des medicamentos que no conozcas ni alimentos al paciente."
            ],
            icon: "cross.case.fill"
        ),
        FirstAidTip(
            title: "Signos de alerta",
            steps: [
                "Dificultad para respirar o dolor intenso en el pecho.",
                "Pérdida de consciencia o convulsiones.",
                "Sangrado abundante que no se detiene.",
                "Informa de inmediato al operador si observas alguno."
            ],
            icon: "exclamationmark.triangle.fill"
        ),
        FirstAidTip(
            title: "Información para el operador",
            steps: [
                "Indica tu ubicación exacta y puntos de referencia cercanos.",
                "Describe qué ocurrió y cuántas personas necesitan ayuda.",
                "Menciona alergias, medicamentos y condiciones médicas conocidas.",
                "No cuelgues hasta que el operador lo indique."
            ],
            icon: "phone.fill"
        )
    ]
}
