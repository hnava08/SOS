import SwiftUI
import UserNotifications

struct SettingsView: View {
    @StateObject private var notifications = NotificationManager.shared
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var accessibility = AccessibilityPreferences.shared
    @ObservedObject private var settings = AppSettingsStore.shared
    @ObservedObject private var network = NetworkMonitor.shared

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notifyAmbulanceAssigned") private var notifyAssigned = true
    @AppStorage("notifyAmbulanceNearby") private var notifyNearby = true
    @AppStorage("notifyAmbulanceArriving") private var notifyArriving = true
    @AppStorage("notifyAmbulanceArrived") private var notifyArrived = true
    @AppStorage("notifySoundEnabled") private var notifySoundEnabled = true

    var body: some View {
        Form {
            languageSection
            notificationsSection
            if notificationsEnabled {
                trackingAlertsSection
                testNotificationSection
            }
            locationSection
            connectionSection
            accessibilitySection
            privacyAndDataSection
            aboutSection
            emergencyCallSection
        }
        .navigationTitle(settings.t("Ajustes", "Settings"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await notifications.refreshAuthorizationStatus()
            notifications.isMasterEnabled = notificationsEnabled
            locationManager.requestPermission()
        }
        .onChange(of: settings.shareLocationInEmergency) { _, value in
            // Mantiene compatibilidad con la clave usada antes.
            UserDefaults.standard.set(value, forKey: "shareLocationAlways")
        }
    }

    private var languageSection: some View {
        Section {
            Picker(settings.t("Idioma", "Language"), selection: $settings.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
        } header: {
            Text(settings.t("Idioma", "Language"))
        } footer: {
            Text(settings.t(
                "Cambia los textos de Ajustes, privacidad y acerca de. El resto de la app permanece en español por ahora.",
                "Changes Settings, privacy and about text. The rest of the app remains in Spanish for now."
            ))
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(
                settings.t("Notificaciones de ambulancia", "Ambulance notifications"),
                isOn: $notificationsEnabled
            )
            .onChange(of: notificationsEnabled) { _, enabled in
                notifications.isMasterEnabled = enabled
                if enabled {
                    Task { await requestNotificationsIfNeeded() }
                }
            }

            HStack {
                Text(settings.t("Permiso del sistema", "System permission"))
                Spacer()
                Text(notificationPermissionLabel)
                    .foregroundStyle(notificationPermissionColor)
                    .font(.subheadline.weight(.semibold))
            }

            if notifications.authorizationStatus == .denied {
                Button(settings.t("Abrir Ajustes del iPhone", "Open iPhone Settings")) {
                    notifications.openSystemSettings()
                }
            } else if notifications.authorizationStatus == .notDetermined {
                Button(settings.t("Permitir notificaciones", "Allow notifications")) {
                    Task { _ = await notifications.requestPermission() }
                }
            }
        } header: {
            Text(settings.t("Notificaciones", "Notifications"))
        } footer: {
            Text(settings.t(
                "Te avisamos cuando la unidad es asignada, está cerca o llega al lugar.",
                "We notify you when a unit is assigned, nearby, or has arrived."
            ))
        }
    }

    private var trackingAlertsSection: some View {
        Section(settings.t("Avisos de seguimiento", "Tracking alerts")) {
            Toggle(settings.t("Ambulancia asignada", "Ambulance assigned"), isOn: $notifyAssigned)
                .onChange(of: notifyAssigned) { _, value in notifications.notifyAssigned = value }
            Toggle(settings.t("Unidad cerca", "Unit nearby"), isOn: $notifyNearby)
                .onChange(of: notifyNearby) { _, value in notifications.notifyNearby = value }
            Toggle(settings.t("Ambulancia llegando", "Ambulance arriving"), isOn: $notifyArriving)
                .onChange(of: notifyArriving) { _, value in notifications.notifyArriving = value }
            Toggle(settings.t("Ambulancia en el lugar", "Ambulance on scene"), isOn: $notifyArrived)
                .onChange(of: notifyArrived) { _, value in notifications.notifyArrived = value }
            Toggle(settings.t("Sonido", "Sound"), isOn: $notifySoundEnabled)
                .onChange(of: notifySoundEnabled) { _, value in notifications.soundEnabled = value }
        }
    }

    private var testNotificationSection: some View {
        Section {
            Button(settings.t("Enviar notificación de prueba", "Send test notification")) {
                Task {
                    let ok = await requestNotificationsIfNeeded()
                    if ok { notifications.sendTestNotification() }
                }
            }
        }
    }

    private var locationSection: some View {
        Section {
            HStack {
                Text(settings.t("Estado", "Status"))
                Spacer()
                Text(locationManager.permissionState.title)
                    .foregroundStyle(locationStatusColor)
                    .font(.subheadline.weight(.semibold))
            }

            Text(locationManager.permissionState.message)
                .font(.caption)
                .foregroundStyle(SOSTheme.secondaryText)

            Toggle(
                settings.t("Usar ubicación en emergencia", "Use location in emergency"),
                isOn: $settings.shareLocationInEmergency
            )

            if locationManager.permissionState == .notDetermined {
                Button(settings.t("Permitir ubicación", "Allow location")) {
                    locationManager.requestPermission()
                }
            }

            if locationManager.permissionState == .denied
                || locationManager.permissionState == .restricted {
                Button(settings.t("Abrir Ajustes del iPhone", "Open iPhone Settings")) {
                    locationManager.openSystemSettings()
                }
            }
        } header: {
            Text(settings.t("Ubicación", "Location"))
        } footer: {
            Text(settings.t(
                "Si deniegas el GPS, aún puedes marcar tu posición en el mapa o elegir un punto de Santa Cruz.",
                "If you deny GPS, you can still mark your position on the map or choose a Santa Cruz landmark."
            ))
        }
    }

    private var connectionSection: some View {
        Section {
            HStack {
                Text(settings.t("Estado de red", "Network status"))
                Spacer()
                Text(network.connectionType.title)
                    .foregroundStyle(network.isOnline ? .green : SOSTheme.primaryRed)
                    .font(.subheadline.weight(.semibold))
            }
            Text(network.statusMessage)
                .font(.caption)
                .foregroundStyle(SOSTheme.secondaryText)
        } header: {
            Text(settings.t("Conexión", "Connection"))
        } footer: {
            Text(settings.t(
                "Sin internet puedes llamar al 911, usar perfil médico, contactos y guía.",
                "Without internet you can call 911, use your medical profile, contacts and guide."
            ))
        }
    }

    private var accessibilitySection: some View {
        Section {
            Toggle(settings.t("Alto contraste", "High contrast"), isOn: $accessibility.highContrastMode)
            Toggle(settings.t("Controles grandes", "Large controls"), isOn: $accessibility.largeControls)
            Toggle(settings.t("Texto más grueso", "Bolder text"), isOn: $accessibility.preferBoldText)
            Toggle(settings.t("Bordes reforzados", "Stronger borders"), isOn: $accessibility.increaseContrastBorders)
        } header: {
            Text(settings.t("Accesibilidad", "Accessibility"))
        } footer: {
            Text(settings.t(
                "También respeta Dynamic Type y Reduce Motion del iPhone (Settings → Accessibility).",
                "Also respects iPhone Dynamic Type and Reduce Motion (Settings → Accessibility)."
            ))
        }
    }

    private var privacyAndDataSection: some View {
        Section(settings.t("Privacidad y datos", "Privacy & data")) {
            NavigationLink {
                AuthGateView()
            } label: {
                Label(
                    AuthStore.shared.isSignedIn
                    ? settings.t("Mi cuenta", "My account")
                    : settings.t("Iniciar sesión / Crear cuenta", "Sign in / Create account"),
                    systemImage: "person.crop.circle.fill"
                )
            }

            NavigationLink {
                SensitiveContentGate(reason: "Desbloquea la configuración de privacidad") {
                    PrivacySettingsView()
                }
            } label: {
                Label(settings.t("Privacidad", "Privacy"), systemImage: "hand.raised.fill")
            }

            NavigationLink {
                EmergencyHistoryView()
            } label: {
                Label(
                    settings.t("Historial de emergencias", "Emergency history"),
                    systemImage: "clock.arrow.circlepath"
                )
            }

            NavigationLink {
                HealthProfileView()
            } label: {
                Label(
                    settings.t("Perfil de salud", "Health profile"),
                    systemImage: "heart.text.square.fill"
                )
            }
        }
    }

    private var aboutSection: some View {
        Section(settings.t("Información", "About")) {
            NavigationLink {
                AboutSOSView()
            } label: {
                Label(settings.t("Acerca de SOS", "About SOS"), systemImage: "info.circle")
            }
            LabeledContent(settings.t("Versión", "Version"), value: settings.appVersion)
            LabeledContent(settings.t("Ciudad", "City"), value: "Santa Cruz de la Sierra")
            LabeledContent(settings.t("Servicio", "Service"), value: "911")
        }
    }

    private var emergencyCallSection: some View {
        Section {
            Link(destination: URL(string: "tel://911")!) {
                Label(settings.t("Llamar al 911", "Call 911"), systemImage: "phone.fill")
                    .foregroundStyle(SOSTheme.primaryRed)
            }
            .accessibilityHint(settings.t(
                "Inicia una llamada de emergencia",
                "Starts an emergency phone call"
            ))
        }
    }

    private var notificationPermissionLabel: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return settings.t("Permitido", "Allowed")
        case .denied:
            return settings.t("Denegado", "Denied")
        case .notDetermined:
            return settings.t("Sin pedir", "Not asked")
        @unknown default:
            return settings.t("Desconocido", "Unknown")
        }
    }

    private var notificationPermissionColor: Color {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return SOSTheme.primaryRed
        case .notDetermined: return .orange
        @unknown default: return SOSTheme.secondaryText
        }
    }

    private var locationStatusColor: Color {
        switch locationManager.permissionState {
        case .authorized: return .green
        case .notDetermined: return .orange
        case .denied, .restricted, .unavailable: return SOSTheme.primaryRed
        }
    }

    @discardableResult
    private func requestNotificationsIfNeeded() async -> Bool {
        if notifications.authorizationStatus == .authorized
            || notifications.authorizationStatus == .provisional {
            return true
        }
        return await notifications.requestPermission()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
