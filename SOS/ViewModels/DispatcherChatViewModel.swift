import Foundation
import UIKit

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isOutgoing: Bool
    let timestamp: Date

    init(text: String, isOutgoing: Bool, timestamp: Date = Date()) {
        self.text = text
        self.isOutgoing = isOutgoing
        self.timestamp = timestamp
    }
}

@MainActor
final class DispatcherChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var draft = ""
    @Published var isTyping = false
    @Published var sendError: String?

    let emergencyType: EmergencyType?
    let unitNumber: String
    let etaText: String
    let phase: TrackingPhase
    private let ticketId: String?

    private let quickReplies = [
        "El paciente está consciente",
        "Hay dificultad para respirar",
        "Hay sangrado",
        "Necesito más indicaciones"
    ]

    var availableQuickReplies: [String] { quickReplies }

    init(
        emergencyType: EmergencyType?,
        unitNumber: String,
        etaText: String,
        phase: TrackingPhase,
        ticketId: String? = nil
    ) {
        self.emergencyType = emergencyType
        self.unitNumber = unitNumber
        self.etaText = etaText
        self.phase = phase
        self.ticketId = ticketId
        seedConversation()
        if ticketId != nil {
            Task { await loadRemoteHistory() }
        }
    }

    func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        send(text)
        draft = ""
    }

    func sendQuickReply(_ text: String) {
        send(text)
    }

    private func send(_ text: String) {
        messages.append(ChatMessage(text: text, isOutgoing: true))
        isTyping = true
        sendError = nil

        Task {
            if let ticketId {
                do {
                    let reply = try await DispatchServerConfig.makeService()?
                        .sendChatMessage(ticketId: ticketId, text: text)
                    isTyping = false
                    if let reply {
                        messages.append(ChatMessage(text: reply.text, isOutgoing: false, timestamp: reply.createdAt))
                        return
                    }
                } catch {
                    sendError = "No se pudo enviar. Respuesta local."
                }
            }

            try? await Task.sleep(nanoseconds: 900_000_000)
            isTyping = false
            messages.append(ChatMessage(text: autoReply(for: text), isOutgoing: false))
        }
    }

    private func loadRemoteHistory() async {
        guard let ticketId else { return }
        do {
            let remote = try await DispatchServerConfig.makeService()?.fetchChat(ticketId: ticketId) ?? []
            guard !remote.isEmpty else { return }
            messages = remote.map {
                ChatMessage(text: $0.text, isOutgoing: $0.isFromUser, timestamp: $0.createdAt)
            }
        } catch {
            // Conserva el saludo local.
        }
    }

    private func seedConversation() {
        let typeText = emergencyType?.title ?? "emergencia médica"
        messages = [
            ChatMessage(
                text: "Despacho SOS. Recibimos tu alerta por \(typeText). Unidad \(unitNumber) asignada · ETA \(etaText).",
                isOutgoing: false
            ),
            ChatMessage(
                text: "Mantén la app abierta. Puedes escribirme si cambia el estado del paciente.",
                isOutgoing: false
            )
        ]
    }

    private func autoReply(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("sangrado") {
            return "Aplica presión firme con un paño limpio. No retires apósitos empapados; añade otro encima. La unidad \(unitNumber) sigue en ruta."
        }
        if lower.contains("respir") {
            return "Siéntalo erguido y afloja la ropa. Si tiene inhalador prescrito, ayúdalo a usarlo. Avisa si labios o uñas se ponen azulados."
        }
        if lower.contains("consciente") {
            return "Perfecto. Quédate a su lado, habla con calma y no le des comida ni líquidos hasta que llegue la ambulancia."
        }
        if lower.contains("indicacion") || lower.contains("ayuda") {
            return "Abre Primeros auxilios en la pantalla del mapa para pasos específicos de \(emergencyType?.title ?? "tu emergencia"). Yo sigo en línea."
        }
        switch phase {
        case .cerca, .llegando:
            return "La unidad \(unitNumber) está cerca (\(etaText)). Despeja el acceso y prepárate para recibir al personal."
        case .llegada:
            return "La unidad ya debería estar en el lugar. Identifícate con el personal y muestra tu perfil de salud."
        case .enCamino:
            return "Recibido. Unidad \(unitNumber) en camino · ETA \(etaText). Te aviso si hay cambios."
        }
    }
}
