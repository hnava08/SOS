import SwiftUI

/// Pantalla de consentimiento obligatorio (política + usos de datos).
struct PrivacyConsentView: View {
    @ObservedObject private var consent = PrivacyConsentStore.shared
    @ObservedObject private var settings = AppSettingsStore.shared

    @State private var medicalShare = true
    @State private var analytics = false
    @State private var acceptedTerms = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    consentCard(
                        title: settings.t("Datos médicos", "Medical data"),
                        body: settings.t(
                            "Tu perfil de salud (sangre, alergias, medicamentos) se guarda cifrado en el Keychain de este iPhone.",
                            "Your health profile (blood type, allergies, medications) is stored encrypted in this iPhone’s Keychain."
                        )
                    )

                    Toggle(isOn: $medicalShare) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.t(
                                "Compartir perfil con despacho en emergencia",
                                "Share profile with dispatch in an emergency"
                            ))
                            .font(.body.weight(.semibold))
                            Text(settings.t(
                                "Solo durante un pedido de ambulancia, y solo si activas esta opción.",
                                "Only during an ambulance request, and only if you enable this."
                            ))
                            .font(.caption)
                            .foregroundStyle(SOSTheme.secondaryText)
                        }
                    }
                    .tint(SOSTheme.primaryRed)

                    Toggle(isOn: $analytics) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.t("Analíticas anónimas", "Anonymous analytics"))
                                .font(.body.weight(.semibold))
                            Text(settings.t(
                                "Ayuda a mejorar la app. No incluye tu perfil médico ni ubicación exacta.",
                                "Helps improve the app. Does not include your medical profile or exact location."
                            ))
                            .font(.caption)
                            .foregroundStyle(SOSTheme.secondaryText)
                        }
                    }
                    .tint(SOSTheme.primaryRed)

                    Toggle(isOn: $acceptedTerms) {
                        Text(settings.t(
                            "He leído y acepto la política de privacidad",
                            "I have read and accept the privacy policy"
                        ))
                        .font(.subheadline.weight(.medium))
                    }
                    .tint(SOSTheme.primaryRed)

                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label(
                            settings.t("Leer política completa", "Read full policy"),
                            systemImage: "doc.text"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SOSTheme.primaryRed)
                    }

                    Button {
                        consent.acceptCurrentPolicy(medicalShare: medicalShare, analytics: analytics)
                    } label: {
                        Text(settings.t("Continuar", "Continue"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(acceptedTerms ? SOSTheme.headerGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!acceptedTerms)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(settings.t("Privacidad", "Privacy"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                medicalShare = consent.medicalShareConsent || consent.needsConsent
                analytics = consent.analyticsConsent
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settings.t("Tu privacidad primero", "Your privacy first"))
                .font(.title.weight(.bold))
            Text(settings.t(
                "Antes de usar SOS necesitamos tu consentimiento sobre cómo se tratan los datos sensibles.",
                "Before using SOS we need your consent on how sensitive data is handled."
            ))
            .foregroundStyle(SOSTheme.secondaryText)
        }
    }

    private func consentCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(SOSTheme.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Bloquea contenido sensible hasta Face ID / código si el usuario lo activó.
struct SensitiveContentGate<Content: View>: View {
    let reason: String
    @ViewBuilder var content: () -> Content

    @ObservedObject private var lock = AppLockStore.shared
    @State private var failed = false

    var body: some View {
        Group {
            if !lock.biometricLockEnabled || lock.isUnlocked {
                content()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SOSTheme.primaryRed)
                    Text("Contenido protegido")
                        .font(.title3.weight(.bold))
                    Text("Usa \(lock.biometryLabel) para ver datos médicos y de cuenta.")
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button {
                        Task {
                            failed = !(await lock.unlock(reason: reason))
                        }
                    } label: {
                        Label("Desbloquear con \(lock.biometryLabel)", systemImage: "faceid")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(SOSTheme.headerGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .padding(.horizontal, 32)
                    }

                    if failed {
                        Text("No se pudo verificar. Intenta de nuevo.")
                            .font(.caption)
                            .foregroundStyle(SOSTheme.primaryRed)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .task {
                    _ = await lock.unlock(reason: reason)
                }
            }
        }
    }
}

#Preview {
    PrivacyConsentView()
}
