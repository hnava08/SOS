import SwiftUI

struct QuickActionsPanel: View {
    var onCallOperator: () -> Void
    var onChat: () -> Void
    var onFirstAid: () -> Void
    var onContacts: () -> Void

    @Environment(\.sosHighContrast) private var highContrast
    @Environment(\.sosLargeControls) private var largeControls

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acciones rápidas")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SOSTheme.secondaryLabel(highContrast: highContrast))
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: largeControls ? 8 : 10) {
                QuickActionTile(
                    title: "Operador",
                    subtitle: "911",
                    icon: "phone.fill",
                    style: .filled,
                    accessibilityHint: "Llama al despacho de emergencias",
                    action: onCallOperator
                )

                QuickActionTile(
                    title: "Chat",
                    subtitle: "Despacho",
                    icon: "message.fill",
                    style: .outlined,
                    accessibilityHint: "Abre el chat con el despachador",
                    action: onChat
                )

                QuickActionTile(
                    title: "Guía",
                    subtitle: "Espera",
                    icon: "list.bullet.clipboard.fill",
                    style: .outlined,
                    accessibilityHint: "Abre la guía mientras llega la ayuda",
                    action: onFirstAid
                )

                QuickActionTile(
                    title: "Familia",
                    subtitle: "Llamar",
                    icon: "person.2.fill",
                    style: .outlined,
                    accessibilityHint: "Muestra contactos de emergencia",
                    action: onContacts
                )
            }
            .accessibilityElement(children: .contain)
        }
        .padding(largeControls ? 16 : 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: highContrast ? .clear : SOSTheme.shadow, radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(highContrast ? Color.black : Color.clear, lineWidth: highContrast ? 2 : 0)
        )
    }
}

private struct QuickActionTile: View {
    enum Style { case filled, outlined }

    let title: String
    let subtitle: String
    let icon: String
    let style: Style
    var accessibilityHint: String = ""
    let action: () -> Void

    @Environment(\.sosHighContrast) private var highContrast
    @Environment(\.sosLargeControls) private var largeControls

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(largeControls ? .title3.weight(.semibold) : .body.weight(.semibold))
                    .frame(width: largeControls ? 44 : 36, height: largeControls ? 44 : 36)
                    .background(iconBackground)
                    .foregroundStyle(iconForeground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)

                VStack(spacing: 1) {
                    Text(title)
                        .font((largeControls ? Font.subheadline : Font.caption).weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(SOSTheme.secondaryLabel(highContrast: highContrast))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, largeControls ? 14 : 10)
            .frame(minHeight: largeControls ? 96 : 80)
            .background(tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: highContrast ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }

    private var iconForeground: Color {
        if highContrast {
            return style == .filled ? .black : .black
        }
        return style == .filled ? .white : SOSTheme.primaryRed
    }

    private var iconBackground: Color {
        if highContrast {
            return style == .filled ? .yellow : Color.white
        }
        return style == .filled ? SOSTheme.primaryRed : SOSTheme.lightRed
    }

    private var tileBackground: Color {
        if highContrast {
            return style == .filled ? Color.yellow.opacity(0.35) : Color.white
        }
        return style == .filled ? SOSTheme.lightRed.opacity(0.55) : Color(.systemGray6).opacity(0.65)
    }

    private var borderColor: Color {
        if highContrast { return .black }
        return style == .outlined ? SOSTheme.lightRed : Color.clear
    }
}

#Preview {
    QuickActionsPanel(
        onCallOperator: {},
        onChat: {},
        onFirstAid: {},
        onContacts: {}
    )
    .padding()
    .background(Color.gray.opacity(0.15))
}
