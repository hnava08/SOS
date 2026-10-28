import SwiftUI

@main
struct SOSApp: App {
    var body: some Scene {
        WindowGroup {
            RootContainer()
        }
    }
}

private struct RootContainer: View {
    @ObservedObject private var accessibility = AccessibilityPreferences.shared
    @ObservedObject private var notifications = NotificationManager.shared
    @State private var introVisible = true

    var body: some View {
        ZStack {
            SOSTheme.primaryRed.ignoresSafeArea()

            if introVisible {
                LaunchIntroView {
                    introVisible = false
                }
            } else {
                ContentView()
                    .environmentObject(HealthProfileStore.shared)
                    .environmentObject(notifications)
                    .environmentObject(NetworkMonitor.shared)
                    .environmentObject(accessibility)
                    .environmentObject(AppSettingsStore.shared)
                    .environmentObject(AuthStore.shared)
                    .sosAccessibilityChrome(
                        highContrast: accessibility.highContrastMode,
                        largeControls: accessibility.largeControls,
                        boldText: accessibility.preferBoldText
                    )
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .onChange(of: introVisible) { _, visible in
            guard !visible else { return }
            Task(priority: .utility) {
                try? await Task.sleep(nanoseconds: 400_000_000)
                await notifications.refreshAuthorizationStatus()
            }
        }
    }
}

/// Nombre de la app al abrir. Solo opacidad y escala, sin redibujar la escena.
private struct LaunchIntroView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var titleOn = false
    @State private var lineOn = false
    @State private var placeOn = false

    var body: some View {
        VStack(spacing: 0) {
            Text("SOS")
                .font(.system(size: 88, weight: .heavy))
                .tracking(10)
                .foregroundStyle(.white)
                .scaleEffect(titleOn ? 1 : 0.94)
                .opacity(titleOn ? 1 : 0)

            Text("EMERGENCIAS MÉDICAS")
                .font(.system(size: 14, weight: .bold))
                .tracking(2.8)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 14)
                .opacity(lineOn ? 1 : 0)
                .offset(y: lineOn ? 0 : 6)

            Text("Santa Cruz de la Sierra")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 8)
                .opacity(placeOn ? 1 : 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("SOS, emergencias médicas, Santa Cruz de la Sierra")
        .task { await play() }
    }

    private func play() async {
        if reduceMotion {
            titleOn = true
            lineOn = true
            placeOn = true
            try? await Task.sleep(nanoseconds: 450_000_000)
            onFinish()
            return
        }

        withAnimation(.easeOut(duration: 0.4)) { titleOn = true }
        try? await Task.sleep(nanoseconds: 200_000_000)
        withAnimation(.easeOut(duration: 0.32)) { lineOn = true }
        try? await Task.sleep(nanoseconds: 140_000_000)
        withAnimation(.easeOut(duration: 0.28)) { placeOn = true }
        try? await Task.sleep(nanoseconds: 620_000_000)
        onFinish()
    }
}
