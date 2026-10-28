import CoreLocation
import Combine
import UIKit

enum LocationSource: String {
    case gps
    case fallback
    case manual

    var label: String {
        switch self {
        case .gps: return "GPS activo"
        case .fallback: return "Ubicación aproximada"
        case .manual: return "Ubicación manual"
        }
    }
}

enum LocationPermissionState {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable

    var title: String {
        switch self {
        case .notDetermined: return "Permiso pendiente"
        case .authorized: return "Ubicación permitida"
        case .denied: return "Ubicación denegada"
        case .restricted: return "Ubicación restringida"
        case .unavailable: return "GPS no disponible"
        }
    }

    var message: String {
        switch self {
        case .notDetermined:
            return "SOS necesita tu ubicación para enviar la ambulancia al lugar correcto."
        case .authorized:
            return "Usamos tu GPS solo durante la emergencia."
        case .denied:
            return "No podemos usar el GPS. Puedes marcar tu posición en el mapa o elegir un punto de Santa Cruz."
        case .restricted:
            return "La ubicación está restringida en este iPhone (controles parentales o perfil). Usa el mapa manual."
        case .unavailable:
            return "No se pudo obtener GPS. Usaremos una ubicación aproximada en Santa Cruz."
        }
    }

    var isUsableGPS: Bool {
        self == .authorized
    }
}

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var permissionState: LocationPermissionState = .notDetermined
    @Published var source: LocationSource = .fallback
    @Published var accuracyMeters: CLLocationAccuracy?
    @Published var lastErrorMessage: String?
    @Published var isUpdating = false

    static let fallbackCoordinate = EmergencyStatus.santaCruzCenter

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        authorizationStatus = manager.authorizationStatus
        permissionState = mapPermission(manager.authorizationStatus)
    }

    var hasPreciseLocation: Bool {
        permissionState.isUsableGPS && userLocation != nil
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdating()
        case .denied, .restricted:
            applyFallbackIfNeeded()
        @unknown default:
            applyFallbackIfNeeded()
        }
    }

    func startUpdating() {
        guard permissionState.isUsableGPS else {
            applyFallbackIfNeeded()
            return
        }
        isUpdating = true
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        isUpdating = false
        manager.stopUpdatingLocation()
    }

    func applyFallbackIfNeeded() {
        if userLocation == nil {
            userLocation = Self.fallbackCoordinate
            source = .fallback
        }
    }

    func setManualLocation(_ coordinate: CLLocationCoordinate2D) {
        userLocation = coordinate
        source = .manual
        accuracyMeters = nil
    }

    func preferGPS() {
        source = .gps
        startUpdating()
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func mapPermission(_ status: CLAuthorizationStatus) -> LocationPermissionState {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unavailable
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            permissionState = mapPermission(manager.authorizationStatus)

            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                startUpdating()
            case .denied, .restricted:
                stopUpdating()
                applyFallbackIfNeeded()
            case .notDetermined:
                break
            @unknown default:
                applyFallbackIfNeeded()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            // No pisar un ajuste manual reciente del usuario.
            if source == .manual { return }
            userLocation = location.coordinate
            accuracyMeters = location.horizontalAccuracy
            source = .gps
            lastErrorMessage = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastErrorMessage = error.localizedDescription
            permissionState = permissionState.isUsableGPS ? .unavailable : permissionState
            applyFallbackIfNeeded()
        }
    }
}
