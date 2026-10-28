import SwiftUI
import UIKit

struct HomeMenuView: View {
    @Binding var path: NavigationPath
    var onRequestAmbulance: () -> Void = {}

    @ObservedObject private var network = NetworkMonitor.shared
    @Environment(\.sosHighContrast) private var highContrast
    @Environment(\.sosLargeControls) private var largeControls
    @State private var appear = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            atmosphere
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    if network.isDegraded {
                        offlineBlock
                    }
                    secondaryActions
                    utilityGrid
                    Spacer(minLength: 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appear = true
            // Pulso corto (no infinito): el forever dejaba el Home pesado al abrir.
            pulse = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    pulse = false
                }
            }
        }
        .animation(.easeOut(duration: 0.45), value: appear)
        .animation(.easeInOut(duration: 1.1), value: pulse)
    }

    // MARK: - Atmosphere

    private var atmosphere: some View {
        ZStack {
            LinearGradient(
                colors: highContrast
                    ? [Color.black, Color(white: 0.12)]
                    : [
                        Color(red: 0.12, green: 0.02, blue: 0.03),
                        Color(red: 0.42, green: 0.04, blue: 0.07),
                        Color(red: 0.72, green: 0.08, blue: 0.10)
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Luz de emergencia suave (no flat).
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.2, blue: 0.18).opacity(highContrast ? 0 : 0.35),
                    .clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 320
            )
            .offset(y: -40)

            // Textura urbana abstracta.
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: 0, y: h * 0.62))
                    path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.62))
                    path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.48))
                    path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.48))
                    path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.55))
                    path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.55))
                    path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.40))
                    path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.40))
                    path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.50))
                    path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.50))
                    path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.44))
                    path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.44))
                    path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.58))
                    path.addLine(to: CGPoint(x: w, y: h * 0.58))
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(Color.black.opacity(highContrast ? 0.45 : 0.22))
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    path.append(HomeDestination.settings)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Ajustes")
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            VStack(spacing: 0) {
                SOSBrandMark(size: .hero, showsPlace: true, centered: true)
                    .scaleEffect(appear ? 1 : 0.94)
                    .opacity(appear ? 1 : 0)
            }
            .padding(.top, 36)
            .padding(.bottom, 8)

            Button(action: onRequestAmbulance) {
                HStack(spacing: 12) {
                    Image(systemName: "ambulance.fill")
                        .font(.title2.weight(.bold))
                    Text("Pedir ambulancia")
                        .font(.system(size: largeControls ? 22 : 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(highContrast ? .black : SOSTheme.primaryRed)
                .frame(maxWidth: .infinity)
                .frame(minHeight: largeControls ? 64 : 58)
                .background(highContrast ? Color.yellow : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(highContrast ? Color.black : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.35), radius: pulse ? 22 : 10, y: 8)
                .scaleEffect(pulse ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .accessibilityLabel("Pedir ambulancia")
            .accessibilityHint("Inicia el pedido de ayuda médica")

            Button {
                if let url = URL(string: "tel://911") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                    Text("Llamar al 911")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .accessibilityLabel("Llamar al 911")
        }
    }

    private var offlineBlock: some View {
        VStack(spacing: 12) {
            OfflineBanner(
                isOnline: false,
                onCall911: {
                    if let url = URL(string: "tel://911") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            OfflineCapabilitiesCard()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Secondary list (quick access)

    private var secondaryActions: some View {
        VStack(spacing: 0) {
            ForEach(HomeMenuItem.featured) { item in
                homeRow(item)
                if item.id != HomeMenuItem.featured.last?.id {
                    Divider().overlay(Color.white.opacity(0.12))
                }
            }
        }
        .background(.ultraThinMaterial.opacity(highContrast ? 0 : 1))
        .background(highContrast ? Color.white : Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(highContrast ? 0 : 0.15), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 16)
    }

    private var utilityGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(HomeMenuItem.utilities) { item in
                Button {
                    path.append(item.destination)
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: item.icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(highContrast ? .black : .white)
                        Text(item.title)
                            .font(.system(size: largeControls ? 16 : 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(highContrast ? .black : .white)
                            .multilineTextAlignment(.leading)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(highContrast ? Color(white: 0.25) : .white.opacity(0.65))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .frame(minHeight: largeControls ? 120 : 108)
                    .background(highContrast ? Color.yellow : Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                highContrast ? Color.black : Color.white.opacity(0.18),
                                lineWidth: highContrast ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.title). \(item.subtitle)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .opacity(appear ? 1 : 0)
    }

    private func homeRow(_ item: HomeMenuItem) -> some View {
        Button {
            path.append(item.destination)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(highContrast ? .black : SOSTheme.primaryRed)
                    .frame(width: largeControls ? 48 : 42, height: largeControls ? 48 : 42)
                    .background(highContrast ? Color.yellow.opacity(0.9) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: largeControls ? 17 : 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(highContrast ? .black : .white)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(highContrast ? Color(white: 0.25) : .white.opacity(0.65))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(highContrast ? .black.opacity(0.5) : .white.opacity(0.45))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, largeControls ? 16 : 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title). \(item.subtitle)")
    }
}

enum HomeDestination: Hashable {
    case profile
    case contacts
    case firstAid
    case history
    case news
    case account
    case settings
}

enum HomeMenuItem: String, CaseIterable, Identifiable {
    case profile
    case contacts
    case firstAid
    case history
    case account
    case news

    var id: String { rawValue }

    /// Acciones de vida (lista principal).
    static var featured: [HomeMenuItem] { [.profile, .contacts, .firstAid] }

    /// Accesos secundarios en grilla.
    static var utilities: [HomeMenuItem] { [.history, .account, .news] }

    var title: String {
        switch self {
        case .profile: return "Perfil de salud"
        case .contacts: return "Contactos"
        case .firstAid: return "Guía de espera"
        case .history: return "Historial"
        case .account: return "Cuenta"
        case .news: return "Noticias"
        }
    }

    var subtitle: String {
        switch self {
        case .profile: return "Sangre, alergias y medicamentos"
        case .contacts: return "Familiares para llamar ya"
        case .firstAid: return "Qué hacer mientras llega"
        case .history: return "Llamados recientes"
        case .account: return "Sesión y sync"
        case .news: return "Alertas locales"
        }
    }

    var icon: String {
        switch self {
        case .profile: return "heart.text.square.fill"
        case .contacts: return "person.2.fill"
        case .firstAid: return "list.bullet.clipboard.fill"
        case .history: return "clock.arrow.circlepath"
        case .account: return "person.crop.circle.fill"
        case .news: return "newspaper.fill"
        }
    }

    var destination: HomeDestination {
        switch self {
        case .profile: return .profile
        case .contacts: return .contacts
        case .firstAid: return .firstAid
        case .history: return .history
        case .account: return .account
        case .news: return .news
        }
    }
}

#Preview {
    NavigationStack {
        HomeMenuView(path: .constant(NavigationPath()))
    }
}
