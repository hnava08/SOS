import SwiftUI

struct PrivacySettingsView: View {
    @ObservedObject private var settings = AppSettingsStore.shared
    @ObservedObject private var consent = PrivacyConsentStore.shared
    @ObservedObject private var lock = AppLockStore.shared
    @State private var showClearConfirm = false
    @State private var didClear = false
    @State private var lockError: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(settings.t("Estado del consentimiento", "Consent status"))
                    Spacer()
                    Text(consent.needsConsent
                         ? settings.t("Pendiente", "Pending")
                         : settings.t("Aceptado", "Accepted"))
                        .foregroundStyle(consent.needsConsent ? .orange : .green)
                        .font(.subheadline.weight(.semibold))
                }

                if let date = consent.acceptedAt {
                    LabeledContent(
                        settings.t("Aceptado el", "Accepted on"),
                        value: date.formatted(date: .abbreviated, time: .shortened)
                    )
                }

                LabeledContent(
                    settings.t("Versión de política", "Policy version"),
                    value: "\(PrivacyConsentStore.currentPolicyVersion)"
                )

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label(
                        settings.t("Política de privacidad", "Privacy policy"),
                        systemImage: "doc.text"
                    )
                }
            } header: {
                Text(settings.t("Consentimiento", "Consent"))
            }

            Section {
                Toggle(
                    settings.t("Compartir ubicación en emergencia", "Share location during emergency"),
                    isOn: $settings.shareLocationInEmergency
                )
                Toggle(
                    settings.t("Compartir perfil de salud con despacho", "Share health profile with dispatch"),
                    isOn: Binding(
                        get: { settings.shareHealthProfileWithDispatch && consent.medicalShareConsent },
                        set: { value in
                            consent.medicalShareConsent = value
                            settings.shareHealthProfileWithDispatch = value
                        }
                    )
                )
                Toggle(
                    settings.t("Guardar historial de emergencias", "Keep emergency history"),
                    isOn: $settings.keepEmergencyHistory
                )
                Toggle(
                    settings.t("Analíticas anónimas", "Anonymous analytics"),
                    isOn: Binding(
                        get: { settings.analyticsEnabled },
                        set: { value in
                            settings.analyticsEnabled = value
                            consent.analyticsConsent = value
                        }
                    )
                )
            } header: {
                Text(settings.t("Datos", "Data"))
            } footer: {
                Text(settings.t(
                    "El perfil médico se guarda cifrado en el Keychain de este iPhone. Solo se envía al despacho si das consentimiento explícito.",
                    "Your medical profile is stored encrypted in this iPhone’s Keychain. It is only sent to dispatch with explicit consent."
                ))
            }

            Section {
                Toggle(
                    settings.t("Bloquear datos sensibles", "Lock sensitive data"),
                    isOn: $lock.biometricLockEnabled
                )
                .disabled(!lock.biometryAvailable && !lock.biometricLockEnabled)
                .onChange(of: lock.biometricLockEnabled) { _, enabled in
                    if enabled {
                        Task {
                            let ok = await lock.unlock(
                                reason: settings.t(
                                    "Activa la protección de datos médicos",
                                    "Enable protection for medical data"
                                )
                            )
                            if !ok {
                                lock.biometricLockEnabled = false
                                lockError = settings.t(
                                    "No se pudo activar \(lock.biometryLabel).",
                                    "Could not enable \(lock.biometryLabel)."
                                )
                            } else {
                                lockError = nil
                            }
                        }
                    }
                }

                if let lockError {
                    Text(lockError)
                        .font(.caption)
                        .foregroundStyle(SOSTheme.primaryRed)
                }
            } header: {
                Text(settings.t("Seguridad", "Security"))
            } footer: {
                Text(settings.t(
                    "Protege perfil médico, contactos y cuenta con \(lock.biometryLabel) o el código del iPhone.",
                    "Protect medical profile, contacts and account with \(lock.biometryLabel) or your device passcode."
                ))
            }

            Section {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label(
                        settings.t("Borrar datos locales", "Erase local data"),
                        systemImage: "trash"
                    )
                }
            } footer: {
                Text(settings.t(
                    "Elimina perfil médico, historial, consentimiento, API key de despacho y desactiva el bloqueo biométrico.",
                    "Deletes medical profile, history, consent, dispatch API key and disables biometric lock."
                ))
            }

            if didClear {
                Section {
                    Text(settings.t("Datos locales borrados.", "Local data erased."))
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle(settings.t("Privacidad", "Privacy"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            settings.t("¿Borrar datos locales?", "Erase local data?"),
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button(settings.t("Borrar", "Erase"), role: .destructive) {
                settings.clearLocalSensitiveData()
                didClear = true
            }
            Button(settings.t("Cancelar", "Cancel"), role: .cancel) {}
        }
    }
}

struct PrivacyPolicyView: View {
    @ObservedObject private var settings = AppSettingsStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(settings.t("Privacidad SOS Santa Cruz", "SOS Santa Cruz Privacy"))
                    .font(.title2.weight(.bold))

                Text(settings.t(
                    "Versión \(PrivacyConsentStore.currentPolicyVersion)",
                    "Version \(PrivacyConsentStore.currentPolicyVersion)"
                ))
                .font(.caption.weight(.semibold))
                .foregroundStyle(SOSTheme.secondaryText)

                policyBlock(
                    title: settings.t("Qué guardamos", "What we store"),
                    body: settings.t(
                        "Perfil de salud y contactos se almacenan cifrados en el Keychain del iPhone. Historial y preferencias viven en almacenamiento local del dispositivo. Las contraseñas de cuenta usan Keychain con acceso solo en este iPhone.",
                        "Health profile and contacts are stored encrypted in the iPhone Keychain. History and preferences live in local device storage. Account passwords use Keychain, this-device-only."
                    )
                )

                policyBlock(
                    title: settings.t("Ubicación", "Location"),
                    body: settings.t(
                        "La ubicación se usa solo durante una emergencia para orientar la ambulancia. Puedes denegar el GPS y marcar tu punto manualmente.",
                        "Location is used only during an emergency to guide the ambulance. You can deny GPS and mark your point manually."
                    )
                )

                policyBlock(
                    title: settings.t("Despacho", "Dispatch"),
                    body: settings.t(
                        "Al pedir una ambulancia, tu ubicación (y el perfil médico solo si lo autorizaste) se envía al centro de despacho para asignar una unidad. Puedes elegir la más cercana o una unidad concreta.",
                        "When you request an ambulance, your location (and medical profile only if authorized) is sent to dispatch to assign a unit. You can choose the closest unit or a specific one."
                    )
                )

                policyBlock(
                    title: settings.t("Llamadas y SMS", "Calls and SMS"),
                    body: settings.t(
                        "Las llamadas al 911 o a familiares usan las apps del sistema. SOS no graba esas conversaciones.",
                        "Calls to 911 or family use system apps. SOS does not record those conversations."
                    )
                )

                policyBlock(
                    title: settings.t("Tus derechos", "Your rights"),
                    body: settings.t(
                        "Puedes retirar el consentimiento, borrar datos locales o eliminar tu cuenta (con borrado de datos médicos) en cualquier momento desde Ajustes → Privacidad o Cuenta.",
                        "You can withdraw consent, erase local data, or delete your account (including medical data) anytime from Settings → Privacy or Account."
                    )
                )
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(settings.t("Privacidad", "Privacy"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policyBlock(title: String, body: String) -> some View {
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

struct AboutSOSView: View {
    @ObservedObject private var settings = AppSettingsStore.shared

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SOS")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(SOSTheme.primaryRed)
                    Text(settings.t(
                        "Emergencias médicas para Santa Cruz de la Sierra.",
                        "Medical emergencies for Santa Cruz de la Sierra."
                    ))
                    .foregroundStyle(SOSTheme.secondaryText)
                }
                .padding(.vertical, 8)
            }

            Section(settings.t("Aplicación", "App")) {
                LabeledContent(settings.t("Versión", "Version"), value: settings.appVersion)
                LabeledContent(settings.t("Ciudad", "City"), value: "Santa Cruz de la Sierra")
                LabeledContent(settings.t("Servicio", "Service"), value: "911")
            }

            Section(settings.t("Contacto de emergencia", "Emergency contact")) {
                Link(destination: URL(string: "tel://911")!) {
                    Label(settings.t("Llamar al 911", "Call 911"), systemImage: "phone.fill")
                        .foregroundStyle(SOSTheme.primaryRed)
                }
            }
        }
        .navigationTitle(settings.t("Acerca de", "About"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
