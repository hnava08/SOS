import SwiftUI

struct SOSHeaderView: View {
    let statusMessage: String
    var onHome: (() -> Void)? = nil

    @Environment(\.sosHighContrast) private var highContrast
    @Environment(\.sosLargeControls) private var largeControls
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            if let onHome {
                Button(action: onHome) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: largeControls ? 44 : 36, height: largeControls ? 44 : 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .accessibleTapTarget()
                .accessibilityLabel("Volver al inicio")
                .accessibilityHint("Cierra el seguimiento de emergencia")
            }

            ZStack {
                Circle()
                    .fill(highContrast ? Color.yellow : Color.white.opacity(0.2))
                    .frame(width: largeControls ? 48 : 44, height: largeControls ? 48 : 44)
                Text("SOS")
                    .font(.system(size: largeControls ? 15 : 14, weight: .black, design: .rounded))
                    .foregroundStyle(highContrast ? .black : .white)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("SOS Santa Cruz")
                    .font(largeControls ? .title3.weight(.bold) : .headline)
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                .scaleEffect(reduceMotion ? 1 : 1.6)
                        )
                        .accessibilityHidden(true)
                    Text(statusMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("SOS Santa Cruz. Estado: \(statusMessage)")

            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityLabel("Notificaciones de emergencia")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, largeControls ? 16 : 14)
        .background(SOSTheme.header(highContrast: highContrast))
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    VStack {
        SOSHeaderView(statusMessage: "Ambulancia en camino")
        SOSHeaderView(statusMessage: "Ambulancia en camino", onHome: {})
    }
    .environment(\.sosHighContrast, true)
}
