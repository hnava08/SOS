import Foundation
import CoreLocation
import Combine
import MapKit

@MainActor
final class EmergencyFlowViewModel: ObservableObject {
    enum Step: Equatable {
        case selectType
        case confirmLocation
        case selectAmbulance
        case dispatching
        case tracking
    }

    @Published var step: Step = .selectType
    @Published var selectedType: EmergencyType?
    @Published var userCoordinate: CLLocationCoordinate2D = EmergencyStatus.santaCruzCenter
    @Published var addressLabel: String = "Plaza 24 de Septiembre, Santa Cruz"
    @Published var isLocating = false
    @Published var locationSource: LocationSource = .fallback
    @Published var assignedUnit: String = ""
    @Published var assignedETA: Int = 0
    @Published var dispatchProgress: Double = 0
    @Published var isOfflineDispatch = false
    @Published var dispatchError: String?
    @Published var activeTicket: DispatchTicket?

    @Published var availableAmbulances: [DispatchAmbulance] = []
    @Published var isLoadingAmbulances = false
    @Published var ambulanceLoadError: String?
    @Published var assignmentMode: AmbulanceAssignmentMode = .closest
    @Published var selectedAmbulance: DispatchAmbulance?

    private var dispatchTask: Task<Void, Never>?
    private let network = NetworkMonitor.shared

    var usesLiveAPI: Bool { activeTicket != nil }

    var closestAmbulance: DispatchAmbulance? {
        availableAmbulances.first
    }

    func selectType(_ type: EmergencyType) {
        selectedType = type
        step = .confirmLocation
    }

    func updateLocation(_ coordinate: CLLocationCoordinate2D) {
        userCoordinate = coordinate
        reverseGeocode(coordinate)
    }

    func confirmLocation() {
        step = .selectAmbulance
        selectedAmbulance = nil
        assignmentMode = .closest
        Task { await loadAmbulances() }
    }

    func loadAmbulances() async {
        guard network.isOnline else {
            ambulanceLoadError = DispatchServiceError.offline.localizedDescription
            availableAmbulances = []
            return
        }
        guard let service = DispatchServerConfig.makeService() else {
            ambulanceLoadError = DispatchServiceError.notConfigured.localizedDescription
            return
        }

        isLoadingAmbulances = true
        ambulanceLoadError = nil
        do {
            availableAmbulances = try await service.fetchAmbulances(
                latitude: userCoordinate.latitude,
                longitude: userCoordinate.longitude
            )
            if availableAmbulances.isEmpty {
                ambulanceLoadError = "No hay ambulancias disponibles ahora. Llama al 911."
            }
        } catch {
            ambulanceLoadError = error.localizedDescription
            availableAmbulances = []
        }
        isLoadingAmbulances = false
    }

    func chooseClosest() {
        assignmentMode = .closest
        selectedAmbulance = closestAmbulance
        confirmAndDispatch()
    }

    func chooseAmbulance(_ ambulance: DispatchAmbulance) {
        assignmentMode = .manual
        selectedAmbulance = ambulance
        confirmAndDispatch()
    }

    func confirmAndDispatch() {
        guard network.isOnline else {
            dispatchError = DispatchServiceError.offline.localizedDescription
            isOfflineDispatch = true
            return
        }
        guard let service = DispatchServerConfig.makeService() else {
            dispatchError = DispatchServiceError.notConfigured.localizedDescription
            return
        }

        if assignmentMode == .manual && selectedAmbulance == nil {
            dispatchError = "Elige una ambulancia para continuar."
            return
        }

        step = .dispatching
        dispatchProgress = 0
        dispatchError = nil
        isOfflineDispatch = false
        activeTicket = nil

        dispatchTask?.cancel()
        dispatchTask = Task {
            let progressTask = Task {
                for value in stride(from: 0.0, through: 0.9, by: 0.05) {
                    guard !Task.isCancelled else { return }
                    dispatchProgress = value
                    try? await Task.sleep(nanoseconds: 70_000_000)
                }
            }

            do {
                let profile = HealthProfileStore.shared.profile
                let shareHealth = AppSettingsStore.shared.shareHealthProfileWithDispatch
                    && PrivacyConsentStore.shared.medicalShareConsent

                let request = CreateDispatchRequest(
                    emergencyType: selectedType?.title ?? "Emergencia médica",
                    addressLabel: addressLabel,
                    latitude: userCoordinate.latitude,
                    longitude: userCoordinate.longitude,
                    userName: AuthStore.shared.currentUser?.fullName ?? profile.fullName,
                    bloodType: shareHealth ? profile.bloodType : nil,
                    allergies: shareHealth ? profile.allergies : nil,
                    medications: shareHealth ? profile.medications : nil,
                    shareHealthProfile: shareHealth,
                    assignmentMode: assignmentMode,
                    ambulanceId: assignmentMode == .manual ? selectedAmbulance?.id : nil
                )

                let ticket = try await service.createEmergency(request)
                progressTask.cancel()
                guard !Task.isCancelled else { return }

                activeTicket = ticket
                assignedUnit = ticket.unitNumber
                assignedETA = ticket.etaMinutes
                dispatchProgress = 1

                NotificationManager.shared.resetSession()
                NotificationManager.shared.notifyAmbulanceAssigned(
                    unitNumber: ticket.unitNumber,
                    etaMinutes: ticket.etaMinutes,
                    emergencyTitle: selectedType?.title ?? "emergencia médica"
                )

                if let type = selectedType, AppSettingsStore.shared.keepEmergencyHistory {
                    EmergencyHistoryStore.shared.startRecord(
                        type: type,
                        unitNumber: ticket.unitNumber,
                        etaMinutes: ticket.etaMinutes,
                        addressLabel: addressLabel,
                        latitude: userCoordinate.latitude,
                        longitude: userCoordinate.longitude
                    )
                }

                step = .tracking
            } catch {
                progressTask.cancel()
                guard !Task.isCancelled else { return }
                dispatchError = error.localizedDescription
                step = .selectAmbulance
            }
        }
    }

    func goBack() {
        switch step {
        case .selectType:
            break
        case .confirmLocation:
            step = .selectType
        case .selectAmbulance:
            step = .confirmLocation
        case .dispatching:
            dispatchTask?.cancel()
            step = .selectAmbulance
        case .tracking:
            step = .selectAmbulance
        }
    }

    func makeEmergencyStatus() -> EmergencyStatus {
        if let ticket = activeTicket {
            return EmergencyStatus(ticket: ticket, statusMessage: selectedType?.statusMessage)
        }

        var status = EmergencyStatus.sample
        status.userCoordinate = userCoordinate
        status.unitNumber = assignedUnit.isEmpty ? "—" : assignedUnit
        status.estimatedArrivalMinutes = max(assignedETA, 1)
        status.statusMessage = selectedType?.statusMessage ?? TrackingPhase.enCamino.title
        status.phase = .enCamino
        if !status.routeCoordinates.isEmpty {
            status.routeCoordinates[status.routeCoordinates.count - 1] = userCoordinate
        }
        return status
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        isLocating = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor in
                guard let self else { return }
                self.isLocating = false
                if let place = placemarks?.first {
                    let parts = [place.name, place.locality].compactMap { $0 }
                    self.addressLabel = parts.isEmpty
                        ? "Santa Cruz de la Sierra"
                        : parts.joined(separator: ", ")
                } else {
                    self.addressLabel = "Santa Cruz de la Sierra"
                }
            }
        }
    }
}

extension EmergencyStatus {
    init(ticket: DispatchTicket, statusMessage: String?) {
        self.unitNumber = ticket.unitNumber
        self.statusMessage = statusMessage ?? TrackingPhase.enCamino.title
        self.estimatedArrivalMinutes = ticket.etaMinutes
        self.ambulanceCoordinate = CLLocationCoordinate2D(
            latitude: ticket.ambulanceLatitude,
            longitude: ticket.ambulanceLongitude
        )
        self.userCoordinate = CLLocationCoordinate2D(
            latitude: ticket.latitude,
            longitude: ticket.longitude
        )
        self.routeCoordinates = ticket.route.map(\.clLocation)
        if self.routeCoordinates.isEmpty {
            self.routeCoordinates = [
                self.ambulanceCoordinate,
                self.userCoordinate
            ]
        }
        self.landmarks = EmergencyStatus.sample.landmarks
        self.phase = .enCamino
    }
}
