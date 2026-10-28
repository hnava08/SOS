import Foundation
import UserNotifications
import Combine
import UIKit

enum SOSNotificationEvent: String {
    case assigned
    case nearby
    case arriving
    case arrived

    var title: String {
        switch self {
        case .assigned: return "Ambulancia asignada"
        case .nearby: return "Unidad cerca"
        case .arriving: return "Ambulancia llegando"
        case .arrived: return "Ambulancia en el lugar"
        }
    }
}

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastErrorMessage: String?

    private let center = UNUserNotificationCenter.current()
    private var notifiedPhases: Set<TrackingPhase> = []

    private enum Keys {
        static let master = "notificationsEnabled"
        static let assigned = "notifyAmbulanceAssigned"
        static let nearby = "notifyAmbulanceNearby"
        static let arriving = "notifyAmbulanceArriving"
        static let arrived = "notifyAmbulanceArrived"
        static let sound = "notifySoundEnabled"
    }

    var isMasterEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.master) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.master) }
    }

    var notifyAssigned: Bool {
        get { UserDefaults.standard.object(forKey: Keys.assigned) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.assigned) }
    }

    var notifyNearby: Bool {
        get { UserDefaults.standard.object(forKey: Keys.nearby) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.nearby) }
    }

    var notifyArriving: Bool {
        get { UserDefaults.standard.object(forKey: Keys.arriving) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.arriving) }
    }

    var notifyArrived: Bool {
        get { UserDefaults.standard.object(forKey: Keys.arrived) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.arrived) }
    }

    var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.sound) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.sound) }
    }

    override init() {
        super.init()
        center.delegate = self
        // No consultar permisos en el init: congela el arranque.
    }

    func resetSession() {
        notifiedPhases.removeAll()
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            lastErrorMessage = error.localizedDescription
            await refreshAuthorizationStatus()
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func notifyAmbulanceAssigned(unitNumber: String, etaMinutes: Int, emergencyTitle: String) {
        guard shouldSend(.assigned) else { return }
        schedule(
            id: "sos.assigned.\(unitNumber)",
            title: SOSNotificationEvent.assigned.title,
            body: "Unidad \(unitNumber) en camino por \(emergencyTitle). ETA \(etaMinutes) min."
        )
    }

    func handlePhaseChange(
        _ phase: TrackingPhase,
        unitNumber: String,
        etaText: String,
        distanceText: String
    ) {
        guard !notifiedPhases.contains(phase) else { return }

        switch phase {
        case .enCamino:
            break
        case .cerca:
            guard shouldSend(.nearby) else { return }
            notifiedPhases.insert(phase)
            schedule(
                id: "sos.nearby.\(unitNumber)",
                title: SOSNotificationEvent.nearby.title,
                body: "La unidad \(unitNumber) está cerca (\(distanceText)). ETA \(etaText)."
            )
        case .llegando:
            guard shouldSend(.arriving) else { return }
            notifiedPhases.insert(phase)
            schedule(
                id: "sos.arriving.\(unitNumber)",
                title: SOSNotificationEvent.arriving.title,
                body: "La ambulancia \(unitNumber) está llegando. Despeja el acceso."
            )
        case .llegada:
            guard shouldSend(.arrived) else { return }
            notifiedPhases.insert(phase)
            schedule(
                id: "sos.arrived.\(unitNumber)",
                title: SOSNotificationEvent.arrived.title,
                body: "La unidad \(unitNumber) ya está en tu ubicación. Identifícate con el personal."
            )
        }
    }

    func sendTestNotification() {
        schedule(
            id: "sos.test.\(UUID().uuidString)",
            title: "SOS · Prueba",
            body: "Las notificaciones de emergencia están activas en este iPhone."
        )
    }

    private func shouldSend(_ event: SOSNotificationEvent) -> Bool {
        guard isMasterEnabled else { return false }
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return false }

        switch event {
        case .assigned: return notifyAssigned
        case .nearby: return notifyNearby
        case .arriving: return notifyArriving
        case .arrived: return notifyArrived
        }
    }

    private func schedule(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = soundEnabled ? .default : nil
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            if let error {
                Task { @MainActor in
                    self?.lastErrorMessage = error.localizedDescription
                }
            }
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
