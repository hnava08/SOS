import SwiftUI

/// Marca SOS. En auth va compacta; en Home, hero.
struct SOSBrandMark: View {
    enum Size {
        case hero
        case welcome
        case auth
        case compact

        var sosSize: CGFloat {
            switch self {
            case .hero: return 72
            case .welcome: return 96
            case .auth: return 28
            case .compact: return 18
            }
        }

        var tracking: CGFloat {
            switch self {
            case .hero: return 8
            case .welcome: return 10
            case .auth: return 3
            case .compact: return 2
            }
        }

        var taglineSize: CGFloat {
            switch self {
            case .welcome: return 14
            case .hero: return 12
            default: return 12
            }
        }

        var placeSize: CGFloat {
            switch self {
            case .welcome: return 17
            case .hero: return 15
            default: return 13
            }
        }
    }

    var size: Size = .hero
    var showsPlace: Bool = true
    var centered: Bool = true
    /// Fondo claro (login kit) vs oscuro/rojo (home).
    var onLightBackground: Bool = false

    private var titleColor: Color { onLightBackground ? SOSTheme.primaryRed : .white }
    private var subtitleColor: Color {
        onLightBackground ? Color(red: 0.12, green: 0.14, blue: 0.17) : .white.opacity(0.88)
    }
    private var placeColor: Color {
        onLightBackground ? Color(red: 0.42, green: 0.45, blue: 0.50) : .white.opacity(0.62)
    }

    var body: some View {
        Group {
            if size == .hero || size == .welcome {
                heroMark
            } else {
                compactMark
            }
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("SOS, emergencias médicas, Santa Cruz de la Sierra")
    }

    private var heroMark: some View {
        VStack(spacing: 0) {
            Text("SOS")
                .font(.system(size: size.sosSize, weight: .heavy, design: .default))
                .foregroundStyle(titleColor)
                .tracking(size.tracking)
                .shadow(
                    color: onLightBackground
                        ? .clear
                        : Color(red: 1, green: 0.15, blue: 0.12).opacity(0.45),
                    radius: 24,
                    y: 0
                )
                .accessibilityAddTraits(.isHeader)

            Text("EMERGENCIAS MÉDICAS")
                .font(.system(size: size.taglineSize, weight: .bold, design: .default))
                .foregroundStyle(subtitleColor)
                .tracking(2.8)
                .padding(.top, size == .welcome ? 12 : 14)

            if showsPlace {
                Text("Santa Cruz de la Sierra")
                    .font(.system(size: size.placeSize, weight: .medium, design: .default))
                    .foregroundStyle(placeColor)
                    .padding(.top, 6)
            }
        }
    }

    /// Auth: una sola línea, sin bloquear el contenido.
    private var compactMark: some View {
        HStack(spacing: 8) {
            Text("SOS")
                .font(.system(size: size.sosSize, weight: .heavy, design: .default))
                .foregroundStyle(titleColor)
                .tracking(size.tracking)

            Rectangle()
                .fill(onLightBackground ? Color.black.opacity(0.12) : Color.white.opacity(0.35))
                .frame(width: 1, height: 14)

            Text(showsPlace ? "Santa Cruz" : "Emergencias")
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundStyle(placeColor)
        }
    }
}
