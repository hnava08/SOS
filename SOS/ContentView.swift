import SwiftUI

struct ContentView: View {
    @State private var showEmergency = false
    @State private var path = NavigationPath()
    @ObservedObject private var consent = PrivacyConsentStore.shared
    @ObservedObject private var auth = AuthStore.shared
    @ObservedObject private var lock = AppLockStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if consent.needsConsent {
                PrivacyConsentView()
            } else if auth.needsAccountPrompt {
                WelcomeAccountView()
            } else {
                NavigationStack(path: $path) {
                    HomeMenuView(
                        path: $path,
                        onRequestAmbulance: { showEmergency = true }
                    )
                    .navigationDestination(for: HomeDestination.self) { destination in
                        destinationView(destination)
                    }
                }
                .tint(SOSTheme.primaryRed)
                .fullScreenCover(isPresented: $showEmergency) {
                    EmergencyFlowView()
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                lock.lockIfNeeded()
            }
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: HomeDestination) -> some View {
        switch destination {
        case .profile:
            SensitiveContentGate(reason: "Desbloquea tu perfil de salud") {
                HealthProfileView()
            }
        case .contacts:
            SensitiveContentGate(reason: "Desbloquea tus contactos de emergencia") {
                EmergencyContactsView()
            }
        case .firstAid:
            WaitingGuideView()
        case .history:
            SensitiveContentGate(reason: "Desbloquea el historial de emergencias") {
                EmergencyHistoryView()
            }
        case .account:
            SensitiveContentGate(reason: "Desbloquea tu cuenta") {
                AuthGateView()
            }
        case .news:
            HealthNewsView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
}
