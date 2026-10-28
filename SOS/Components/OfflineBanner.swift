import SwiftUI

struct OfflineBanner: View {
    let isOnline: Bool
    var compact: Bool = false
    var onCall911: (() -> Void)? = nil

    var body: some View {
        if !isOnline {
            VStack(alignment: .leading, spacing: compact ? 6 : 10) {
                HStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Modo sin conexión")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        if !compact {
                            Text("911, perfil médico y guía funcionan offline. El despacho real quedará pendiente hasta recuperar red.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 0)
                }

                if let onCall911, !compact {
                    Button(action: onCall911) {
                        Label("Llamar al 911 ahora", systemImage: "phone.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SOSTheme.primaryRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(compact ? 10 : 14)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.55, green: 0.08, blue: 0.1), SOSTheme.darkRed],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous))
        }
    }
}

struct OfflineCapabilitiesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disponible sin internet")
                .font(.headline)

            capability(icon: "phone.fill", title: "Llamar al 911", detail: "Siempre disponible por red telefónica")
            capability(icon: "heart.text.square.fill", title: "Perfil de salud", detail: "Datos médicos guardados en el iPhone")
            capability(icon: "person.2.fill", title: "Contactos", detail: "Llamadas y SMS a familiares")
            capability(icon: "list.bullet.clipboard.fill", title: "Guía de espera", detail: "Pasos locales mientras llega ayuda")
            capability(icon: "ambulance.fill", title: "Pedido local", detail: "Simulación / cola local hasta recuperar red")
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
    }

    private func capability(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(SOSTheme.primaryRed)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(SOSTheme.secondaryText)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        OfflineBanner(isOnline: false, onCall911: {})
        OfflineCapabilitiesCard()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
