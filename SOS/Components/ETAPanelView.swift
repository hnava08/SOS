import SwiftUI

struct ETAPanelView: View {
    let unitNumber: String
    let etaText: String
    let distanceText: String
    let phase: TrackingPhase
    let progress: Double

    @Environment(\.sosHighContrast) private var highContrast
    @Environment(\.sosLargeControls) private var largeControls
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(phase.badge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(highContrast ? .black : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(highContrast ? Color.yellow : phaseColor)
                    .clipShape(Capsule())
                    .accessibilityLabel("Estado \(phase.title)")

                Spacer()

                Image(systemName: "ambulance.fill")
                    .font(.title3)
                    .foregroundStyle(highContrast ? .black : SOSTheme.primaryRed)
                    .symbolEffect(
                        .pulse,
                        options: .repeating,
                        isActive: !reduceMotion && phase != .llegada
                    )
                    .accessibilityHidden(true)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unidad")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SOSTheme.secondaryLabel(highContrast: highContrast))
                    Text(unitNumber)
                        .font((largeControls ? Font.title : Font.title2).weight(.bold))
                        .foregroundStyle(highContrast ? .black : SOSTheme.primaryRed)
                }

                Divider().frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("ETA")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SOSTheme.secondaryLabel(highContrast: highContrast))
                    Text(etaText)
                        .font((largeControls ? Font.title : Font.title2).weight(.bold))
                        .foregroundStyle(highContrast ? .black : SOSTheme.primaryRed)
                }

                Divider().frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Distancia")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SOSTheme.secondaryLabel(highContrast: highContrast))
                    Text(distanceText)
                        .font((largeControls ? Font.title2 : Font.title3).weight(.bold))
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)
            }

            ProgressView(value: min(max(progress, 0), 1))
                .tint(highContrast ? .black : SOSTheme.primaryRed)
                .accessibilityLabel("Progreso de llegada")
                .accessibilityValue("\(Int(progress * 100)) por ciento")

            Text(phase.title)
                .font(.caption)
                .foregroundStyle(SOSTheme.secondaryLabel(highContrast: highContrast))
        }
        .padding(largeControls ? 18 : 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: highContrast ? .clear : SOSTheme.shadow, radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(highContrast ? Color.black : Color.clear, lineWidth: highContrast ? 2 : 0)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unidad \(unitNumber), tiempo estimado \(etaText), distancia \(distanceText), \(phase.title)")
    }

    private var phaseColor: Color {
        switch phase {
        case .enCamino: return SOSTheme.primaryRed
        case .cerca: return Color.orange
        case .llegando: return Color(red: 0.85, green: 0.45, blue: 0.05)
        case .llegada: return Color.green
        }
    }
}

#Preview {
    ETAPanelView(
        unitNumber: "A-31",
        etaText: "8 min",
        distanceText: "1.2 km",
        phase: .enCamino,
        progress: 0.35
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
