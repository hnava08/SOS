import SwiftUI

struct LocationPermissionBanner: View {
    let state: LocationPermissionState
    let source: LocationSource
    var accuracyText: String? = nil
    var onRequestPermission: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 34, height: 34)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title)
                        .font(.subheadline.weight(.bold))
                    Text(state.message)
                        .font(.caption)
                        .foregroundStyle(SOSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                Text(source.label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SOSTheme.lightRed)
                    .clipShape(Capsule())

                if let accuracyText {
                    Text(accuracyText)
                        .font(.caption2)
                        .foregroundStyle(SOSTheme.secondaryText)
                }

                Spacer()
            }

            if state == .notDetermined, let onRequestPermission {
                Button("Permitir ubicación", action: onRequestPermission)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SOSTheme.primaryRed)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if state == .denied || state == .restricted, let onOpenSettings {
                Button("Abrir Ajustes del iPhone", action: onOpenSettings)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SOSTheme.lightRed)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
    }

    private var iconName: String {
        switch state {
        case .authorized: return "location.fill"
        case .notDetermined: return "location.circle"
        case .denied, .restricted: return "location.slash.fill"
        case .unavailable: return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .authorized: return .green
        case .notDetermined: return .orange
        case .denied, .restricted, .unavailable: return SOSTheme.primaryRed
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        LocationPermissionBanner(state: .denied, source: .fallback, onOpenSettings: {})
        LocationPermissionBanner(state: .authorized, source: .gps, accuracyText: "±12 m")
    }
    .padding()
    .background(Color.gray.opacity(0.15))
}
