import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isOnline = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive = false

    enum ConnectionType: String {
        case wifi
        case cellular
        case wired
        case unknown
        case offline

        var title: String {
            switch self {
            case .wifi: return "Wi‑Fi"
            case .cellular: return "Datos móviles"
            case .wired: return "Ethernet"
            case .unknown: return "Conectado"
            case .offline: return "Sin conexión"
            }
        }
    }

    var isDegraded: Bool { !isOnline }

    var statusMessage: String {
        if isOnline {
            return "Conexión activa · \(connectionType.title)"
        }
        return "Sin internet. Puedes llamar al 911, ver tu perfil y contactos."
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "sos.network.monitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.apply(path: path)
            }
        }
        monitor.start(queue: queue)
    }

    private func apply(path: NWPath) {
        isOnline = path.status == .satisfied
        isExpensive = path.isExpensive

        if path.status != .satisfied {
            connectionType = .offline
            return
        }

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }
    }
}
