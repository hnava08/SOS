import SwiftUI
import Combine

@MainActor
final class AccessibilityPreferences: ObservableObject {
    static let shared = AccessibilityPreferences()

    @Published var highContrastMode: Bool {
        didSet { UserDefaults.standard.set(highContrastMode, forKey: Keys.highContrast) }
    }

    @Published var largeControls: Bool {
        didSet { UserDefaults.standard.set(largeControls, forKey: Keys.largeControls) }
    }

    @Published var preferBoldText: Bool {
        didSet { UserDefaults.standard.set(preferBoldText, forKey: Keys.boldText) }
    }

    @Published var increaseContrastBorders: Bool {
        didSet { UserDefaults.standard.set(increaseContrastBorders, forKey: Keys.borders) }
    }

    private enum Keys {
        static let highContrast = "highContrastMode"
        static let largeControls = "largeControlsEnabled"
        static let boldText = "preferBoldText"
        static let borders = "increaseContrastBorders"
    }

    private init() {
        let defaults = UserDefaults.standard
        highContrastMode = defaults.object(forKey: Keys.highContrast) as? Bool ?? false
        largeControls = defaults.object(forKey: Keys.largeControls) as? Bool ?? true
        preferBoldText = defaults.object(forKey: Keys.boldText) as? Bool ?? false
        increaseContrastBorders = defaults.object(forKey: Keys.borders) as? Bool ?? false
    }

    var minimumTapSize: CGFloat {
        largeControls ? 52 : 44
    }

    var controlPadding: CGFloat {
        largeControls ? 18 : 14
    }
}

private struct SOSHighContrastKey: EnvironmentKey {
    static let defaultValue = false
}

private struct SOSLargeControlsKey: EnvironmentKey {
    static let defaultValue = true
}

private struct SOSBoldTextKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var sosHighContrast: Bool {
        get { self[SOSHighContrastKey.self] }
        set { self[SOSHighContrastKey.self] = newValue }
    }

    var sosLargeControls: Bool {
        get { self[SOSLargeControlsKey.self] }
        set { self[SOSLargeControlsKey.self] = newValue }
    }

    var sosBoldText: Bool {
        get { self[SOSBoldTextKey.self] }
        set { self[SOSBoldTextKey.self] = newValue }
    }
}

struct SOSAccessibleButtonStyle: ButtonStyle {
    @Environment(\.sosLargeControls) private var largeControls
    @Environment(\.sosHighContrast) private var highContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var role: Role = .primary

    enum Role {
        case primary, secondary, destructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(largeControls ? .headline.weight(.bold) : .subheadline.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, largeControls ? 18 : 14)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: highContrast ? 2 : 0)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch role {
        case .primary: return .white
        case .secondary: return highContrast ? .black : SOSTheme.primaryRed
        case .destructive: return .white
        }
    }

    private var background: Color {
        switch role {
        case .primary: return highContrast ? .black : SOSTheme.primaryRed
        case .secondary: return highContrast ? Color.yellow.opacity(0.35) : Color.white
        case .destructive: return highContrast ? .black : SOSTheme.darkRed
        }
    }

    private var borderColor: Color {
        highContrast ? .black : .clear
    }
}

struct AccessibleTapTarget: ViewModifier {
    @Environment(\.sosLargeControls) private var largeControls

    func body(content: Content) -> some View {
        content
            .frame(minWidth: largeControls ? 52 : 44, minHeight: largeControls ? 52 : 44)
            .contentShape(Rectangle())
    }
}

extension View {
    func accessibleTapTarget() -> some View {
        modifier(AccessibleTapTarget())
    }

    func sosAccessibilityChrome(
        highContrast: Bool,
        largeControls: Bool,
        boldText: Bool
    ) -> some View {
        self
            .environment(\.sosHighContrast, highContrast)
            .environment(\.sosLargeControls, largeControls)
            .environment(\.sosBoldText, boldText)
            .fontWeight(boldText ? .semibold : .regular)
    }
}
