import Foundation

struct WaitingGuideStep: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let icon: String

    init(id: String, title: String, detail: String, icon: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.icon = icon
    }
}

struct WaitingGuideContent {
    let type: EmergencyType?
    let headline: String
    let summary: String
    let doSteps: [WaitingGuideStep]
    let avoidSteps: [WaitingGuideStep]
    let whenToAlertOperator: [String]

    static func general() -> WaitingGuideContent {
        WaitingGuideContent(
            type: nil,
            headline: "Mientras llega la ayuda",
            summary: "Pasos claros para mantener la seguridad hasta que arribe la ambulancia.",
            doSteps: [
                WaitingGuideStep(
                    id: "mant-n-la-calma",
                    title: "Mantén la calma",
                    detail: "Respira profundo. Habla con voz serena. El pánico dificulta ayudar.",
                    icon: "lungs.fill"
                ),
                WaitingGuideStep(
                    id: "qu-date-en-el-lugar",
                    title: "Quédate en el lugar",
                    detail: "No te alejes salvo que haya peligro inmediato (fuego, tráfico, colapso).",
                    icon: "mappin.and.ellipse"
                ),
                WaitingGuideStep(
                    id: "despeja-el-acceso",
                    title: "Despeja el acceso",
                    detail: "Abre puertas, quita obstáculos y señala la entrada para la ambulancia.",
                    icon: "door.left.hand.open"
                ),
                WaitingGuideStep(
                    id: "ten-el-perfil-listo",
                    title: "Ten el perfil listo",
                    detail: "Grupo sanguíneo, alergias y medicamentos deben estar visibles para el personal.",
                    icon: "doc.text.fill"
                )
            ],
            avoidSteps: [
                WaitingGuideStep(
                    id: "no-des-comida-ni-l-quidos",
                    title: "No des comida ni líquidos",
                    detail: "Puede complicar una posible intervención médica.",
                    icon: "fork.knife"
                ),
                WaitingGuideStep(
                    id: "no-muevas-al-paciente-sin-necesidad",
                    title: "No muevas al paciente sin necesidad",
                    detail: "Especialmente si hay sospecha de lesión de cuello o espalda.",
                    icon: "hand.raised.fill"
                )
            ],
            whenToAlertOperator: [
                "Pierde la conciencia o deja de responder",
                "Deja de respirar o respira con mucha dificultad",
                "El sangrado no se detiene con presión",
                "El dolor de pecho empeora de forma intensa"
            ]
        )
    }

    static func forType(_ type: EmergencyType) -> WaitingGuideContent {
        let base = general()
        let specific = specificSteps(for: type)
        let avoid = specificAvoid(for: type)
        let alerts = specificAlerts(for: type)

        return WaitingGuideContent(
            type: type,
            headline: "Guía · \(type.title)",
            summary: "Qué hacer ahora mismo mientras la unidad se dirige a tu ubicación.",
            doSteps: base.doSteps + specific,
            avoidSteps: avoid.isEmpty ? base.avoidSteps : avoid,
            whenToAlertOperator: alerts.isEmpty ? base.whenToAlertOperator : alerts
        )
    }

    private static func specificSteps(for type: EmergencyType) -> [WaitingGuideStep] {
        switch type {
        case .chestPain:
            return [
                WaitingGuideStep(
                    id: "si-ntalo-y-que-repose",
                    title: "Siéntalo y que repose",
                    detail: "Evita que camine o haga esfuerzo. Afloja ropa del pecho y cuello.",
                    icon: "figure.seated.side"
                ),
                WaitingGuideStep(
                    id: "observa-cambios",
                    title: "Observa cambios",
                    detail: "Sudor frío, náuseas, dolor que se irradia al brazo o mandíbula: avisa al operador.",
                    icon: "eye.fill"
                )
            ]
        case .accident:
            return [
                WaitingGuideStep(
                    id: "inmoviliza-si-hay-trauma",
                    title: "Inmoviliza si hay trauma",
                    detail: "Si sospechas cuello/espalda, no lo muevas. Solo sácalo si hay peligro vital inmediato.",
                    icon: "figure.fall"
                ),
                WaitingGuideStep(
                    id: "controla-sangrados",
                    title: "Controla sangrados",
                    detail: "Presión firme con paño limpio. No retires apósitos empapados: añade otro encima.",
                    icon: "bandage.fill"
                )
            ]
        case .breathing:
            return [
                WaitingGuideStep(
                    id: "posici-n-erguida",
                    title: "Posición erguida",
                    detail: "Siéntalo inclinado hacia adelante. Busca aire fresco y abre ventanas.",
                    icon: "wind"
                ),
                WaitingGuideStep(
                    id: "inhalador-solo-si-est-prescrito",
                    title: "Inhalador solo si está prescrito",
                    detail: "Ayúdalo con su medicación conocida. No improvises otros fármacos.",
                    icon: "allergens"
                )
            ]
        case .unconscious:
            return [
                WaitingGuideStep(
                    id: "verifica-respuesta-y-respiraci-n",
                    title: "Verifica respuesta y respiración",
                    detail: "Habla fuerte y toca los hombros. Mira si el pecho sube y baja.",
                    icon: "person.fill.questionmark"
                ),
                WaitingGuideStep(
                    id: "posici-n-lateral-si-respira",
                    title: "Posición lateral si respira",
                    detail: "Si respira, colócalo de lado. Si no respira, sigue las indicaciones del operador.",
                    icon: "bed.double.fill"
                )
            ]
        case .bleeding:
            return [
                WaitingGuideStep(
                    id: "presi-n-continua",
                    title: "Presión continua",
                    detail: "No sueltes la presión. Si puedes, eleva la zona herida por encima del corazón.",
                    icon: "drop.fill"
                ),
                WaitingGuideStep(
                    id: "objetos-clavados",
                    title: "Objetos clavados",
                    detail: "No los retires. Inmovilízalos con ropa limpia alrededor y espera a la ambulancia.",
                    icon: "exclamationmark.triangle.fill"
                )
            ]
        case .other:
            return [
                WaitingGuideStep(
                    id: "describe-lo-que-ves",
                    title: "Describe lo que ves",
                    detail: "Anota hora, síntomas y cambios para informar al personal al llegar.",
                    icon: "list.clipboard.fill"
                )
            ]
        }
    }

    private static func specificAvoid(for type: EmergencyType) -> [WaitingGuideStep] {
        switch type {
        case .chestPain:
            return [
                WaitingGuideStep(
                    id: "no-lo-hagas-caminar",
                    title: "No lo hagas caminar",
                    detail: "Cualquier esfuerzo puede empeorar el cuadro.",
                    icon: "figure.walk"
                ),
                WaitingGuideStep(
                    id: "no-des-estimulantes",
                    title: "No des estimulantes",
                    detail: "Evita café, energizantes o medicación no indicada por su médico.",
                    icon: "cup.and.saucer.fill"
                )
            ]
        case .unconscious:
            return [
                WaitingGuideStep(
                    id: "nada-por-la-boca",
                    title: "Nada por la boca",
                    detail: "No des agua, comida ni pastillas a alguien inconsciente.",
                    icon: "nosign"
                )
            ]
        case .bleeding:
            return [
                WaitingGuideStep(
                    id: "no-uses-torniquete-improvisado",
                    title: "No uses torniquete improvisado",
                    detail: "Salvo instrucción explícita del operador capacitado.",
                    icon: "xmark.circle.fill"
                )
            ]
        default:
            return general().avoidSteps
        }
    }

    private static func specificAlerts(for type: EmergencyType) -> [String] {
        switch type {
        case .chestPain:
            return [
                "El dolor se intensifica o se irradia al brazo/mandíbula",
                "Aparece sudor frío, náuseas o desmayo",
                "Dificultad marcada para respirar"
            ]
        case .breathing:
            return [
                "Labios o uñas se ponen azulados",
                "No puede hablar por falta de aire",
                "Pierde la conciencia"
            ]
        case .unconscious:
            return [
                "Deja de respirar",
                "Convulsiona",
                "No recupera la respuesta"
            ]
        case .bleeding:
            return [
                "La sangre empapa apósitos muy rápido",
                "La persona se pone pálida o confusa",
                "Hay objeto clavado profundo"
            ]
        case .accident:
            return [
                "Pérdida de sensibilidad en extremidades",
                "Dolor intenso de cuello o espalda",
                "Vómitos reiterados o confusión"
            ]
        case .other:
            return general().whenToAlertOperator
        }
    }
}
