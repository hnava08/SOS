import Foundation

/// Cliente HTTP del despacho SOS.
final class APIDispatchService: DispatchService {
    private let baseURL: URL
    private let apiKey: String?
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, apiKey: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let withFractional = ISO8601DateFormatter()
            withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFractional.date(from: value) { return date }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Fecha ISO8601 inválida: \(value)"
            )
        }

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func fetchAmbulances(latitude: Double, longitude: Double) async throws -> [DispatchAmbulance] {
        let path = "v1/ambulances?latitude=\(latitude)&longitude=\(longitude)&available=true"
        let response: AmbulancesResponse = try await get(path: path)
        return response.ambulances
    }

    func createEmergency(_ request: CreateDispatchRequest) async throws -> DispatchTicket {
        try await post(path: "v1/emergencies", body: request)
    }

    func fetchTicket(id: String) async throws -> DispatchTicket {
        try await get(path: "v1/emergencies/\(id)")
    }

    func sendChatMessage(ticketId: String, text: String) async throws -> DispatchChatMessageDTO {
        struct Body: Codable { let text: String }
        return try await post(path: "v1/emergencies/\(ticketId)/chat", body: Body(text: text))
    }

    func fetchChat(ticketId: String) async throws -> [DispatchChatMessageDTO] {
        try await get(path: "v1/emergencies/\(ticketId)/chat")
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        let request = try makeRequest(path: path, method: "GET", bodyData: nil)
        return try await send(request)
    }

    private func post<Body: Encodable, T: Decodable>(path: String, body: Body) async throws -> T {
        let data = try encoder.encode(body)
        let request = try makeRequest(path: path, method: "POST", bodyData: data)
        return try await send(request)
    }

    private func makeRequest(path: String, method: String, bodyData: Data?) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw DispatchServiceError.notConfigured
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = bodyData
        request.timeoutInterval = 20
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw DispatchServiceError.invalidResponse
            }

            if !(200...299).contains(http.statusCode) {
                if let server = try? decoder.decode(ServerErrorDTO.self, from: data) {
                    throw DispatchServiceError.server(message: server.message)
                }
                throw DispatchServiceError.server(message: "HTTP \(http.statusCode)")
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw DispatchServiceError.decoding
            }
        } catch let error as DispatchServiceError {
            throw error
        } catch {
            throw DispatchServiceError.network(underlying: error)
        }
    }
}

private struct ServerErrorDTO: Codable {
    var message: String
}
