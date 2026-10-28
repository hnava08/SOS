import SwiftUI

struct EmergencyTabView: View {
    var emergencyStatus: EmergencyStatus = .sample
    var emergencyType: EmergencyType? = nil
    var ticketId: String? = nil
    var useLivePolling: Bool = false
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: AppTab = .map

    var body: some View {
        VStack(spacing: 0) {
            if selectedTab != .map {
                homeBar
            }

            TabView(selection: $selectedTab) {
                MapScreenView(
                    onHome: { close() },
                    status: emergencyStatus,
                    emergencyType: emergencyType,
                    ticketId: ticketId,
                    useLivePolling: useLivePolling
                )
                .tabItem {
                    Label(AppTab.map.title, systemImage: AppTab.map.icon)
                }
                .tag(AppTab.map)

                NavigationStack {
                    HealthProfileView()
                }
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                }
                .tag(AppTab.profile)

                NavigationStack {
                    HealthNewsView()
                }
                .tabItem {
                    Label(AppTab.news.title, systemImage: AppTab.news.icon)
                }
                .tag(AppTab.news)

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
            }
            .tint(SOSTheme.primaryRed)
        }
    }

    private var homeBar: some View {
        Button {
            close()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                Text("Inicio")
                    .font(.body.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(SOSTheme.primaryRed)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

enum AppTab: Hashable {
    case map, profile, news, settings

    var title: String {
        switch self {
        case .map: return "Mapa"
        case .profile: return "Perfil"
        case .news: return "Noticias"
        case .settings: return "Ajustes"
        }
    }

    var icon: String {
        switch self {
        case .map: return "map.fill"
        case .profile: return "heart.text.square.fill"
        case .news: return "newspaper.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

#Preview {
    EmergencyTabView()
}
