import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit
import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
    @Published var emergencyStatus: EmergencyStatus
    @Published var cameraPosition: MapCameraPosition
    @Published var etaMinutes: Int
    @Published var distanceMeters: CLLocationDistance = 0
    @Published var routeProgress: Double = 0
    @Published var showFirstAidTips = false
    @Published var showChatSheet = false
    @Published var showCallOperator = false
    @Published var showContacts = false
    @Published var followAmbulance = true
    @Published var selectedLandmark: Landmark?

    var emergencyContacts: [EmergencyContact] {
        HealthProfileStore.shared.profile.emergencyContacts
    }

    private var simulationTimer: AnyCancellable?
    private var pollTask: Task<Void, Never>?
    private let initialETA: Int
    private var baseStatusMessage: String
    private let ticketId: String?
    private let useLivePolling: Bool

    init(
        status: EmergencyStatus = .sample,
        ticketId: String? = nil,
        useLivePolling: Bool = false
    ) {
        self.emergencyStatus = status
        self.etaMinutes = status.estimatedArrivalMinutes
        self.initialETA = max(status.estimatedArrivalMinutes, 1)
        self.baseStatusMessage = status.statusMessage
        self.ticketId = ticketId
        self.useLivePolling = useLivePolling
        let center = CLLocationCoordinate2D(
            latitude: (status.ambulanceCoordinate.latitude + status.userCoordinate.latitude) / 2,
            longitude: (status.ambulanceCoordinate.longitude + status.userCoordinate.longitude) / 2
        )
        self.cameraPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        )
        refreshDistance()

        if useLivePolling, ticketId != nil {
            startPolling()
        } else {
            startAmbulanceSimulation()
        }
    }

    var ambulanceCoordinate: CLLocationCoordinate2D {
        emergencyStatus.ambulanceCoordinate
    }

    var destinationCoordinate: CLLocationCoordinate2D {
        emergencyStatus.userCoordinate
    }

    var fullRoute: [CLLocationCoordinate2D] {
        emergencyStatus.routeCoordinates
    }

    var remainingRoute: [CLLocationCoordinate2D] {
        routeSlice(fromProgress: routeProgress)
    }

    var traveledRoute: [CLLocationCoordinate2D] {
        let traveled = routeSlice(fromProgress: 0, toProgress: routeProgress)
        if traveled.isEmpty {
            return [ambulanceCoordinate]
        }
        return traveled
    }

    var phase: TrackingPhase {
        emergencyStatus.phase
    }

    var etaText: String {
        if phase == .llegada { return "En sitio" }
        if etaMinutes <= 1 { return "< 1 min" }
        return "\(etaMinutes) min"
    }

    var distanceText: String {
        if phase == .llegada { return "0 m" }
        if distanceMeters >= 1000 {
            return String(format: "%.1f km", distanceMeters / 1000)
        }
        return "\(Int(distanceMeters)) m"
    }

    func callOperator() {
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
    }

    func callContact(_ contact: EmergencyContact) {
        let digits = contact.phoneNumber.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)") {
            UIApplication.shared.open(url)
        }
    }
    func recenterOnRoute() {
        followAmbulance = true
        updateCamera(animated: true)
    }

    func toggleFollow() {
        followAmbulance.toggle()
        if followAmbulance {
            updateCamera(animated: true)
        }
    }

    private func startAmbulanceSimulation() {
        simulationTimer = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.advanceAmbulance()
            }
    }

    private func advanceAmbulance() {
        let route = emergencyStatus.routeCoordinates
        guard route.count >= 2, phase != .llegada else { return }

        routeProgress = min(routeProgress + 0.045, 1.0)
        emergencyStatus.ambulanceCoordinate = coordinate(at: routeProgress)
        refreshDistance()

        let remainingFraction = max(0, 1.0 - routeProgress)
        etaMinutes = max(phase == .llegada ? 0 : 1, Int(ceil(Double(initialETA) * remainingFraction)))

        updatePhase()
        if followAmbulance {
            updateCamera(animated: true)
        }

        if routeProgress >= 1.0 {
            simulationTimer?.cancel()
            let previous = emergencyStatus.phase
            emergencyStatus.phase = .llegada
            emergencyStatus.statusMessage = TrackingPhase.llegada.title
            etaMinutes = 0
            distanceMeters = 0
            if previous != .llegada {
                notifyPhaseIfNeeded(.llegada)
            }
        }
    }

    private func updatePhase() {
        let previous = emergencyStatus.phase
        let newPhase: TrackingPhase
        if routeProgress >= 1.0 {
            newPhase = .llegada
        } else if routeProgress >= 0.85 || distanceMeters < 250 {
            newPhase = .llegando
        } else if routeProgress >= 0.55 || distanceMeters < 800 {
            newPhase = .cerca
        } else {
            newPhase = .enCamino
        }

        emergencyStatus.phase = newPhase

        if newPhase == .enCamino, baseStatusMessage.contains("·") {
            emergencyStatus.statusMessage = baseStatusMessage
        } else {
            emergencyStatus.statusMessage = newPhase.title
        }

        if previous != newPhase {
            notifyPhaseIfNeeded(newPhase)
        }
    }

    private func notifyPhaseIfNeeded(_ phase: TrackingPhase) {
        NotificationManager.shared.handlePhaseChange(
            phase,
            unitNumber: emergencyStatus.unitNumber,
            etaText: etaText,
            distanceText: distanceText
        )

        if phase == .llegada {
            EmergencyHistoryStore.shared.markArrived(unitNumber: emergencyStatus.unitNumber)
        }
    }

    private func refreshDistance() {
        let from = CLLocation(
            latitude: ambulanceCoordinate.latitude,
            longitude: ambulanceCoordinate.longitude
        )
        let to = CLLocation(
            latitude: destinationCoordinate.latitude,
            longitude: destinationCoordinate.longitude
        )
        distanceMeters = from.distance(from: to)
    }

    private func updateCamera(animated: Bool) {
        let region = MKCoordinateRegion(
            center: midpoint(ambulanceCoordinate, destinationCoordinate),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.012, abs(ambulanceCoordinate.latitude - destinationCoordinate.latitude) * 2.4 + 0.01),
                longitudeDelta: max(0.012, abs(ambulanceCoordinate.longitude - destinationCoordinate.longitude) * 2.4 + 0.01)
            )
        )
        withAnimation(animated ? .easeInOut(duration: 0.8) : nil) {
            cameraPosition = .region(region)
        }
    }

    private func coordinate(at progress: Double) -> CLLocationCoordinate2D {
        let route = emergencyStatus.routeCoordinates
        guard route.count >= 2 else { return ambulanceCoordinate }

        let clamped = min(max(progress, 0), 1)
        let segmentCount = Double(route.count - 1)
        let scaled = clamped * segmentCount
        let index = min(Int(scaled), route.count - 2)
        let fraction = scaled - Double(index)

        let start = route[index]
        let end = route[index + 1]
        return CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * fraction,
            longitude: start.longitude + (end.longitude - start.longitude) * fraction
        )
    }

    private func routeSlice(fromProgress: Double, toProgress: Double = 1.0) -> [CLLocationCoordinate2D] {
        let route = emergencyStatus.routeCoordinates
        guard route.count >= 2 else { return [] }

        let start = coordinate(at: fromProgress)
        let end = coordinate(at: toProgress)
        var points: [CLLocationCoordinate2D] = [start]

        let segmentCount = Double(route.count - 1)
        let startIndex = Int(fromProgress * segmentCount) + 1
        let endIndex = Int(toProgress * segmentCount)

        if startIndex <= endIndex {
            for i in startIndex...min(endIndex, route.count - 1) {
                points.append(route[i])
            }
        }

        points.append(end)
        return points
    }

    private func midpoint(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (a.latitude + b.latitude) / 2,
            longitude: (a.longitude + b.longitude) / 2
        )
    }

    private func startPolling() {
        guard let ticketId else {
            startAmbulanceSimulation()
            return
        }

        pollTask = Task {
            while !Task.isCancelled {
                do {
                    guard let service = DispatchServerConfig.makeService() else {
                        throw DispatchServiceError.notConfigured
                    }
                    let ticket = try await service.fetchTicket(id: ticketId)
                    applyTicket(ticket)
                    if ticket.status == "arrived" || ticket.status == "closed" {
                        break
                    }
                } catch {
                    // Si falla el poll, continúa con la ruta ya recibida.
                    if simulationTimer == nil {
                        startAmbulanceSimulation()
                    }
                    break
                }
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }

    private func applyTicket(_ ticket: DispatchTicket) {
        let previousPhase = emergencyStatus.phase

        emergencyStatus.unitNumber = ticket.unitNumber
        emergencyStatus.ambulanceCoordinate = CLLocationCoordinate2D(
            latitude: ticket.ambulanceLatitude,
            longitude: ticket.ambulanceLongitude
        )
        emergencyStatus.userCoordinate = CLLocationCoordinate2D(
            latitude: ticket.latitude,
            longitude: ticket.longitude
        )
        if !ticket.route.isEmpty {
            emergencyStatus.routeCoordinates = ticket.route.map(\.clLocation)
        }
        etaMinutes = ticket.etaMinutes
        emergencyStatus.estimatedArrivalMinutes = ticket.etaMinutes

        let progress = min(max(1.0 - (Double(ticket.etaMinutes) / Double(max(initialETA, 1))), 0), 1)
        routeProgress = progress
        let newPhase = phase(from: ticket.status, progress: progress)
        emergencyStatus.phase = newPhase
        emergencyStatus.statusMessage = statusMessage(for: newPhase)

        refreshDistance()
        if followAmbulance {
            updateCamera(animated: true)
        }

        if previousPhase != newPhase {
            notifyPhaseIfNeeded(newPhase)
        }
    }

    private func phase(from status: String, progress: Double) -> TrackingPhase {
        switch status.lowercased() {
        case "arrived", "closed", "on_scene":
            return .llegada
        case "arriving":
            return .llegando
        case "nearby", "cerca":
            return .cerca
        default:
            if progress >= 0.92 { return .llegando }
            if progress >= 0.7 { return .cerca }
            return .enCamino
        }
    }

    private func statusMessage(for phase: TrackingPhase) -> String {
        switch phase {
        case .enCamino: return baseStatusMessage
        case .cerca: return TrackingPhase.cerca.title
        case .llegando: return TrackingPhase.llegando.title
        case .llegada: return TrackingPhase.llegada.title
        }
    }

    deinit {
        simulationTimer?.cancel()
        pollTask?.cancel()
    }
}
