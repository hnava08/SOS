import Foundation

/// Configuración del servidor de despacho (solo para desarrollo / despliegue).
/// No se muestra en la UI del usuario.
enum DispatchServerConfig {
    /// URL base con barra final. Cámbiala a la IP de tu Mac o al dominio de producción.
    static let baseURLString: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "SOSDispatchBaseURL") as? String,
           !value.isEmpty {
            return value.hasSuffix("/") ? value : value + "/"
        }
        return "http://192.168.1.205:3000/"
    }()

    static let apiKey: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "SOSDispatchAPIKey") as? String,
           !value.isEmpty {
            return value
        }
        return "sos-dev-key"
    }()

    static var baseURL: URL? {
        URL(string: baseURLString)
    }

    static func makeService() -> DispatchService? {
        guard let url = baseURL else { return nil }
        return APIDispatchService(baseURL: url, apiKey: apiKey)
    }
}
