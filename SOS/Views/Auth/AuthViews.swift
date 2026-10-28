import SwiftUI
import UIKit
import AuthenticationServices

/// Flujo basado en Login & Register App UI Kit (FruzzDigital / Community),
/// con tokens de color SOS.
enum AuthPath: Equatable {
    case welcome
    case login
    case register
    case phone
    case google
}

private enum AuthKit {
    static let ink = Color(red: 0.118, green: 0.137, blue: 0.173)       // #1E232C
    static let muted = Color(red: 0.416, green: 0.439, blue: 0.486)     // #6A707C
    static let fieldFill = Color(red: 0.969, green: 0.973, blue: 0.976) // #F7F8F9
    static let fieldBorder = Color(red: 0.910, green: 0.925, blue: 0.957) // #E8ECF4
    static let divider = Color(red: 0.851, green: 0.851, blue: 0.851)   // #D9D9D9
    static let radius: CGFloat = 8
    static let buttonHeight: CGFloat = 56
    static let fieldHeight: CGFloat = 56
}

struct AuthGateView: View {
    @ObservedObject private var auth = AuthStore.shared

    var body: some View {
        Group {
            if auth.isSignedIn {
                AccountView()
            } else {
                AuthCanvas()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct WelcomeAccountView: View {
    var body: some View {
        AuthCanvas()
    }
}

struct AuthCanvas: View {
    @ObservedObject private var auth = AuthStore.shared
    @Environment(\.sosHighContrast) private var highContrast
    @StateObject private var appleSignIn = AppleSignInCoordinator()

    @State private var path: AuthPath = .welcome
    @State private var errorMessage: String?
    @State private var isWorking = false

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = "+591 "
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    @State private var phoneNumber = "+591 "
    @State private var otpCode = ""
    @State private var otpSent = false
    @State private var debugOTP: String?

    @State private var googleEmail = ""
    @State private var googleName = ""

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            switch path {
            case .welcome:
                welcomeLayout
            case .login:
                formShell { loginForm }
            case .register:
                formShell { registerForm }
            case .phone:
                formShell { phoneForm }
            case .google:
                formShell { googleForm }
            }
        }
        .onAppear {
            appleSignIn.onCompletion = handleApple
        }
        .onChange(of: appleSignIn.lastError) { _, newValue in
            if let newValue {
                errorMessage = newValue
            }
        }
    }

    private var background: some View {
        Group {
            if path == .welcome {
                LinearGradient(
                    colors: highContrast
                        ? [Color.black, Color(white: 0.12)]
                        : [
                            Color(red: 0.55, green: 0.06, blue: 0.09),
                            SOSTheme.primaryRed,
                            SOSTheme.darkRed
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.white
            }
        }
    }

    // MARK: - Welcome (kit)

    private var welcomeLayout: some View {
        VStack(spacing: 0) {
            SOSBrandMark(size: .welcome, showsPlace: true, centered: true)
                .padding(.top, 20)

            AmbulanceRescueAnimation()
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                AuthPrimaryButton(title: "Iniciar sesión", isWorking: false) {
                    errorMessage = nil
                    path = .login
                }

                AuthSecondaryButton(title: "Registrarse") {
                    errorMessage = nil
                    path = .register
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Shell formulario (kit: back + scroll + footer)

    private func formShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                AuthBackButton {
                    goBack()
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                content()
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 20)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            footerSwitch
                .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private var footerSwitch: some View {
        switch path {
        case .login:
            AuthFooterLink(
                prefix: "¿No tienes cuenta? ",
                actionTitle: "Regístrate"
            ) {
                errorMessage = nil
                path = .register
            }
        case .register:
            AuthFooterLink(
                prefix: "¿Ya tienes cuenta? ",
                actionTitle: "Inicia sesión"
            ) {
                errorMessage = nil
                path = .login
            }
        default:
            EmptyView()
        }
    }

    private func goBack() {
        errorMessage = nil
        switch path {
        case .login, .register:
            path = .welcome
        case .phone, .google:
            path = .login
        case .welcome:
            break
        }
    }

    // MARK: - Login

    private var loginForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("¡Bienvenido de nuevo!\nNos alegra verte otra vez.")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AuthKit.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 14) {
                AuthTextField(
                    icon: "at",
                    placeholder: "Correo electrónico",
                    text: $email,
                    keyboard: .emailAddress,
                    autocap: .never
                )

                AuthSecureField(
                    placeholder: "Contraseña",
                    text: $password,
                    isRevealed: $showPassword
                )
            }
            .padding(.top, 28)

            HStack {
                Spacer()
                Text("¿Olvidaste tu contraseña?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AuthKit.muted)
            }
            .padding(.top, 8)

            AuthPrimaryButton(title: "Iniciar sesión", isWorking: isWorking) {
                submitLogin()
            }
            .padding(.top, 28)

            AuthOrDivider(label: "O inicia con")
                .padding(.top, 20)

            socialRow
                .padding(.top, 12)
        }
    }

    // MARK: - Register

    private var registerForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("¡Hola! Regístrate\npara comenzar")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AuthKit.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 14) {
                AuthTextField(
                    icon: "person",
                    placeholder: "Nombre completo",
                    text: $fullName
                )
                AuthTextField(
                    icon: "at",
                    placeholder: "Correo electrónico",
                    text: $email,
                    keyboard: .emailAddress,
                    autocap: .never
                )
                AuthTextField(
                    icon: "phone",
                    placeholder: "Teléfono",
                    text: $phone,
                    keyboard: .phonePad
                )
                AuthSecureField(
                    placeholder: "Contraseña",
                    text: $password,
                    isRevealed: $showPassword
                )
                AuthSecureField(
                    placeholder: "Confirmar contraseña",
                    text: $confirmPassword,
                    isRevealed: $showConfirmPassword
                )
            }
            .padding(.top, 28)

            AuthPrimaryButton(title: "Registrarse", isWorking: isWorking) {
                submitRegister()
            }
            .padding(.top, 24)

            AuthOrDivider(label: "O regístrate con")
                .padding(.top, 20)

            socialRow
                .padding(.top, 12)
        }
    }

    private var socialRow: some View {
        HStack(spacing: 10) {
            AuthSocialIconButton(kind: .apple) {
                errorMessage = nil
                appleSignIn.start()
            }
            AuthSocialIconButton(kind: .google) {
                errorMessage = nil
                path = .google
            }
            AuthSocialIconButton(kind: .phone) {
                errorMessage = nil
                otpSent = false
                debugOTP = nil
                path = .phone
            }
        }
    }

    // MARK: - Phone / Google (secundarios)

    private var phoneForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(otpSent ? "Verifica tu código" : "Continuar con celular")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AuthKit.ink)

            Text(otpSent
                 ? "Ingresa el código de 6 dígitos que enviamos."
                 : "Te enviaremos un código por SMS.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AuthKit.muted)
                .padding(.top, 8)

            VStack(spacing: 14) {
                AuthTextField(
                    icon: "phone",
                    placeholder: "Celular",
                    text: $phoneNumber,
                    keyboard: .phonePad
                )
                if otpSent {
                    AuthTextField(
                        icon: "number",
                        placeholder: "Código de 6 dígitos",
                        text: $otpCode,
                        keyboard: .numberPad
                    )
                    if let debugOTP {
                        Text("Código de prueba: \(debugOTP)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AuthKit.muted)
                    }
                }
            }
            .padding(.top, 28)

            AuthPrimaryButton(
                title: otpSent ? "Verificar" : "Enviar código",
                isWorking: isWorking
            ) {
                Task {
                    if otpSent {
                        await verifyPhone()
                    } else {
                        await sendPhoneCode()
                    }
                }
            }
            .padding(.top, 28)
        }
    }

    private var googleForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Continuar con Google")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AuthKit.ink)

            Text("Usa el correo de tu cuenta Google.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AuthKit.muted)
                .padding(.top, 8)

            VStack(spacing: 14) {
                AuthTextField(
                    icon: "at",
                    placeholder: "Correo de Google",
                    text: $googleEmail,
                    keyboard: .emailAddress,
                    autocap: .never
                )
                AuthTextField(
                    icon: "person",
                    placeholder: "Nombre",
                    text: $googleName
                )
            }
            .padding(.top, 28)

            AuthPrimaryButton(title: "Continuar", isWorking: false, action: submitGoogle)
                .padding(.top, 28)
        }
    }

    // MARK: - Actions

    private func submitLogin() {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitRegister() {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            guard password == confirmPassword else {
                errorMessage = "Las contraseñas no coinciden."
                return
            }
            try auth.register(fullName: fullName, email: email, phone: phone, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        // El coordinator ya aplica AuthStore; aquí solo limpiamos cancelaciones.
        if case .failure(let error) = result {
            let ns = error as NSError
            if ns.domain == ASAuthorizationError.errorDomain,
               ns.code == ASAuthorizationError.canceled.rawValue {
                return
            }
        }
    }

    private func submitGoogle() {
        errorMessage = nil
        do {
            let name = googleName.isEmpty
                ? String(googleEmail.split(separator: "@").first ?? "Usuario")
                : googleName
            try auth.signInWithGoogle(email: googleEmail, fullName: name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendPhoneCode() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            debugOTP = try await auth.requestPhoneCode(phone: phoneNumber)
            otpSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func verifyPhone() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await auth.verifyPhoneCode(phone: phoneNumber, code: otpCode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Kit components (FruzzDigital → SOS)

private struct AuthBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AuthKit.ink)
                .frame(width: 41, height: 41)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AuthKit.fieldBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct AuthPrimaryButton: View {
    let title: String
    var isWorking: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isWorking {
                    ProgressView().tint(.white)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AuthKit.buttonHeight)
            .background(SOSTheme.primaryRed)
            .clipShape(RoundedRectangle(cornerRadius: AuthKit.radius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
    }
}

private struct AuthSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AuthKit.buttonHeight)
                .background(Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: AuthKit.radius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .words

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AuthKit.muted)
                .frame(width: 22)
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AuthKit.muted))
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocap)
                .autocorrectionDisabled()
                .font(.system(size: 15))
                .foregroundStyle(AuthKit.ink)
        }
        .padding(.horizontal, 14)
        .frame(height: AuthKit.fieldHeight)
        .background(AuthKit.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: AuthKit.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AuthKit.radius, style: .continuous)
                .strokeBorder(AuthKit.fieldBorder, lineWidth: 1)
        }
    }
}

private struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isRevealed: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AuthKit.muted)
                .frame(width: 22)

            Group {
                if isRevealed {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AuthKit.muted))
                } else {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(AuthKit.muted))
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 15))
            .foregroundStyle(AuthKit.ink)

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye" : "eye.slash")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AuthKit.muted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: AuthKit.fieldHeight)
        .background(AuthKit.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: AuthKit.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AuthKit.radius, style: .continuous)
                .strokeBorder(AuthKit.fieldBorder, lineWidth: 1)
        }
    }
}

private struct AuthOrDivider: View {
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(AuthKit.divider).frame(height: 1)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AuthKit.ink)
                .fixedSize()
            Rectangle().fill(AuthKit.divider).frame(height: 1)
        }
    }
}

private struct AuthSocialIconButton: View {
    enum Kind {
        case apple, google, phone
    }

    let kind: Kind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                switch kind {
                case .apple:
                    Image(systemName: "apple.logo")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.black)
                case .google:
                    Image("GoogleG")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                case .phone:
                    Image(systemName: "phone.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AuthKit.ink)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AuthKit.fieldBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AuthFooterLink: View {
    let prefix: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            (Text(prefix)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AuthKit.ink)
             + Text(actionTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(SOSTheme.primaryRed))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Apple Sign In

@MainActor
final class AppleSignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?
    @Published var lastError: String?

    /// Debe retenerse: si se libera, el sheet de Apple no aparece.
    private var activeController: ASAuthorizationController?
    private var anchorWindow: UIWindow?

    func start() {
        lastError = nil
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        activeController = controller
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        activeController = nil
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            lastError = "No se pudo leer la cuenta de Apple."
            onCompletion?(.failure(AuthError.invalidCredentials))
            return
        }
        do {
            try AuthStore.shared.signInWithApple(credential: credential)
            onCompletion?(.success(authorization))
        } catch {
            lastError = error.localizedDescription
            onCompletion?(.failure(error))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        activeController = nil
        let ns = error as NSError
        if ns.domain == ASAuthorizationError.errorDomain,
           ns.code == ASAuthorizationError.canceled.rawValue {
            onCompletion?(.failure(error))
            return
        }
        if ns.domain == ASAuthorizationError.errorDomain, ns.code == 1000 {
            lastError = "Iniciar sesión con Apple no está disponible en este iPhone. La cuenta de desarrollador es personal y Apple solo permite ese botón con una membresía de pago. Usa correo y contraseña."
        } else {
            lastError = error.localizedDescription
        }
        onCompletion?(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }

        let windows = scenes.flatMap(\.windows)
        if let key = windows.first(where: \.isKeyWindow) {
            return key
        }
        if let visible = windows.first(where: { !$0.isHidden && $0.alpha > 0 }) {
            return visible
        }
        if let scene = scenes.first {
            let anchor = anchorWindow ?? UIWindow(windowScene: scene)
            anchor.frame = scene.coordinateSpace.bounds
            anchor.isHidden = false
            anchorWindow = anchor
            return anchor
        }
        return windows.first ?? ASPresentationAnchor()
    }
}

struct AccountView: View {
    @ObservedObject private var auth = AuthStore.shared
    @State private var fullName = ""
    @State private var phone = ""
    @State private var showDeleteSheet = false
    @State private var deletePassword = ""
    @State private var eraseMedicalData = true
    @State private var message: String?
    @State private var messageIsError = false

    var body: some View {
        Form {
            if let user = auth.currentUser {
                Section("Cuenta") {
                    LabeledContent("Acceso", value: user.provider.title)
                    if !user.email.isEmpty {
                        LabeledContent("Correo", value: user.email)
                    }
                    TextField("Nombre", text: $fullName)
                    TextField("Teléfono", text: $phone)
                        .keyboardType(.phonePad)
                    Button("Guardar cambios") {
                        do {
                            try auth.updateProfile(fullName: fullName, phone: phone)
                            message = "Perfil actualizado."
                            messageIsError = false
                        } catch {
                            message = error.localizedDescription
                            messageIsError = true
                        }
                    }
                }

                Section {
                    Toggle(
                        "Preparar sync en la nube",
                        isOn: Binding(
                            get: { auth.currentUser?.syncEnabled ?? false },
                            set: { auth.setCloudSyncEnabled($0) }
                        )
                    )
                    Text(auth.lastSyncMessage)
                        .font(.caption)
                        .foregroundStyle(SOSTheme.secondaryText)
                } header: {
                    Text("Sincronización")
                }

                Section("Accesos rápidos") {
                    NavigationLink {
                        HealthProfileView()
                    } label: {
                        Label("Perfil de salud", systemImage: "heart.text.square.fill")
                    }
                    NavigationLink {
                        EmergencyContactsView()
                    } label: {
                        Label("Contactos de emergencia", systemImage: "person.2.fill")
                    }
                }

                if let message {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(messageIsError ? SOSTheme.primaryRed : .green)
                    }
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        auth.signOut()
                    }
                    Button("Eliminar cuenta", role: .destructive) {
                        showDeleteSheet = true
                    }
                }
            }
        }
        .navigationTitle("Mi cuenta")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            fullName = auth.currentUser?.fullName ?? ""
            phone = auth.currentUser?.phone ?? ""
        }
        .sheet(isPresented: $showDeleteSheet) {
            NavigationStack {
                Form {
                    if auth.currentUser?.provider == .email {
                        Section {
                            SecureField("Confirma tu contraseña", text: $deletePassword)
                        }
                    }
                    Section {
                        Toggle("También borrar perfil médico e historial", isOn: $eraseMedicalData)
                    }
                    Section {
                        Button("Eliminar cuenta", role: .destructive) {
                            do {
                                try auth.deleteAccount(
                                    password: auth.currentUser?.provider == .email ? deletePassword : nil,
                                    eraseMedicalData: eraseMedicalData
                                )
                                showDeleteSheet = false
                            } catch {
                                message = error.localizedDescription
                                messageIsError = true
                                showDeleteSheet = false
                            }
                            deletePassword = ""
                        }
                        .disabled(auth.currentUser?.provider == .email && deletePassword.isEmpty)
                    }
                }
                .navigationTitle("Eliminar cuenta")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cerrar") { showDeleteSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    WelcomeAccountView()
}
