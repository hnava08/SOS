import SwiftUI

struct CriticalInfoBlock: View {
    let title: String
    let value: String
    let icon: String

    @Environment(\.sosHighContrast) private var highContrast
    @Environment(\.sosLargeControls) private var largeControls
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(largeControls ? .title : .title2)
                .foregroundStyle(highContrast ? .black : .white)
                .frame(width: largeControls ? 52 : 44, height: largeControls ? 52 : 44)
                .background(highContrast ? Color.yellow : Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(highContrast ? .white.opacity(0.9) : .white.opacity(0.85))
                    .tracking(0.5)
                Text(value)
                    .font(largeControls ? .title2.weight(.bold) : .title3.weight(.bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
            }

            Spacer()
        }
        .padding(largeControls ? 18 : 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SOSTheme.header(highContrast: highContrast))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(highContrast ? Color.yellow : Color.white.opacity(0.15), lineWidth: highContrast ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    VStack(spacing: 12) {
        CriticalInfoBlock(title: "Grupo Sanguíneo", value: "O+", icon: "drop.fill")
        CriticalInfoBlock(title: "Alergias", value: "Penicilina", icon: "allergens")
    }
    .padding()
    .environment(\.sosHighContrast, true)
}
