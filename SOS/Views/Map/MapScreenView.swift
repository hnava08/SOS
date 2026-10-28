import SwiftUI
import MapKit

struct MapScreenView: View {
    var onHome: (() -> Void)? = nil
    var emergencyType: EmergencyType? = nil
    private let ticketId: String?

    @StateObject private var viewModel: MapViewModel
    @StateObject private var locationManager = LocationManager()

    init(
        onHome: (() -> Void)? = nil,
        status: EmergencyStatus = .sample,
        emergencyType: EmergencyType? = nil,
        ticketId: String? = nil,
        useLivePolling: Bool = false
    ) {
        self.onHome = onHome
        self.emergencyType = emergencyType
        self.ticketId = ticketId
        _viewModel = StateObject(
            wrappedValue: MapViewModel(
                status: status,
                ticketId: ticketId,
                useLivePolling: useLivePolling
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mapLayer
                overlayContent
            }
            .navigationBarHidden(true)
            .onAppear {
                locationManager.requestPermission()
                locationManager.startUpdating()
            }
            .sheet(isPresented: $viewModel.showFirstAidTips) {
                NavigationStack {
                    WaitingGuideView(
                        initialType: emergencyType,
                        showsCloseButton: true,
                        isEmergencyActive: true
                    )
                }
            }
            .sheet(isPresented: $viewModel.showChatSheet) {
                DispatcherChatView(
                    emergencyType: emergencyType,
                    unitNumber: viewModel.emergencyStatus.unitNumber,
                    etaText: viewModel.etaText,
                    phase: viewModel.phase,
                    ticketId: ticketId
                )
            }
            .sheet(isPresented: $viewModel.showCallOperator) {
                CallOperatorSheet(
                    emergencyType: emergencyType,
                    unitNumber: viewModel.emergencyStatus.unitNumber,
                    etaText: viewModel.etaText,
                    onConfirmCall: { viewModel.callOperator() }
                )
            }
            .sheet(isPresented: $viewModel.showContacts) {
                EmergencyContactsSheet()
            }
        }
    }

    private var mapLayer: some View {
        Map(position: $viewModel.cameraPosition) {
            UserAnnotation()

            Annotation("Destino", coordinate: viewModel.destinationCoordinate) {
                DestinationMarkerView()
            }

            Annotation("Ambulancia \(viewModel.emergencyStatus.unitNumber)", coordinate: viewModel.ambulanceCoordinate) {
                AmbulanceMarkerView(phase: viewModel.phase)
            }

            ForEach(viewModel.emergencyStatus.landmarks) { landmark in
                Annotation(landmark.name, coordinate: landmark.coordinate) {
                    Button {
                        viewModel.selectedLandmark = landmark
                    } label: {
                        LandmarkMarkerView(
                            icon: landmark.icon,
                            isSelected: viewModel.selectedLandmark?.id == landmark.id
                        )
                    }
                }
            }

            MapPolyline(coordinates: viewModel.traveledRoute)
                .stroke(Color.gray.opacity(0.45), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

            MapPolyline(coordinates: viewModel.remainingRoute)
                .stroke(SOSTheme.routeRed, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.hospital, .pharmacy, .park])))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(edges: .bottom)
        .onMapCameraChange { _ in
            // Si el usuario mueve el mapa, dejamos de seguir automáticamente.
        }
    }

    private var overlayContent: some View {
        VStack(spacing: 0) {
            SOSHeaderView(
                statusMessage: viewModel.emergencyStatus.statusMessage,
                onHome: onHome
            )

            if !NetworkMonitor.shared.isOnline {
                OfflineBanner(isOnline: false, compact: true)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            if viewModel.phase == .llegada {
                arrivalBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack {
                Spacer()
                mapTools
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Spacer()

            VStack(spacing: 10) {
                if let landmark = viewModel.selectedLandmark {
                    landmarkCard(landmark)
                }

                ETAPanelView(
                    unitNumber: viewModel.emergencyStatus.unitNumber,
                    etaText: viewModel.etaText,
                    distanceText: viewModel.distanceText,
                    phase: viewModel.phase,
                    progress: viewModel.routeProgress
                )

                quickActions
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.phase)
    }

    private var arrivalBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
            Text("La unidad \(viewModel.emergencyStatus.unitNumber) ya está en el lugar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(12)
        .background(Color.green)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var mapTools: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.toggleFollow()
            } label: {
                Image(systemName: viewModel.followAmbulance ? "location.fill" : "location")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(viewModel.followAmbulance ? .white : SOSTheme.primaryRed)
                    .frame(width: 42, height: 42)
                    .background(viewModel.followAmbulance ? SOSTheme.primaryRed : Color.white)
                    .clipShape(Circle())
                    .shadow(color: SOSTheme.shadow, radius: 4, y: 2)
            }

            Button {
                viewModel.recenterOnRoute()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .frame(width: 42, height: 42)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: SOSTheme.shadow, radius: 4, y: 2)
            }
        }
    }

    private func landmarkCard(_ landmark: Landmark) -> some View {
        HStack(spacing: 10) {
            Image(systemName: landmark.icon)
                .foregroundStyle(SOSTheme.primaryRed)
            Text(landmark.name)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                viewModel.selectedLandmark = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(SOSTheme.secondaryText)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
    }

    private var quickActions: some View {
        QuickActionsPanel(
            onCallOperator: { viewModel.showCallOperator = true },
            onChat: { viewModel.showChatSheet = true },
            onFirstAid: { viewModel.showFirstAidTips = true },
            onContacts: { viewModel.showContacts = true }
        )
    }
}

struct AmbulanceMarkerView: View {
    var phase: TrackingPhase = .enCamino

    var body: some View {
        ZStack {
            Circle()
                .fill(markerColor.opacity(0.25))
                .frame(width: 56, height: 56)
            Circle()
                .fill(markerColor)
                .frame(width: 42, height: 42)
            Image(systemName: phase == .llegada ? "checkmark" : "ambulance.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: markerColor.opacity(0.4), radius: 6, y: 2)
    }

    private var markerColor: Color {
        phase == .llegada ? .green : SOSTheme.primaryRed
    }
}

struct DestinationMarkerView: View {
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundStyle(SOSTheme.primaryRed)
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                )
            Text("Tú")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: SOSTheme.shadow, radius: 2, y: 1)
        }
    }
}

struct LandmarkMarkerView: View {
    let icon: String
    var isSelected: Bool = false

    var body: some View {
        Image(systemName: icon)
            .font(.caption)
            .foregroundStyle(isSelected ? .white : SOSTheme.primaryRed)
            .padding(7)
            .background(isSelected ? SOSTheme.primaryRed : Color.white)
            .clipShape(Circle())
            .shadow(color: SOSTheme.shadow, radius: 4, y: 2)
    }
}

struct ActionButton: View {
    enum Style {
        case primary, secondary, outline
    }

    let title: String
    let icon: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(foregroundColor)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .outline ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary, .outline: return SOSTheme.primaryRed
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            SOSTheme.headerGradient
        case .secondary, .outline:
            Color.white.opacity(0.95)
        }
    }

    private var borderColor: Color {
        style == .outline ? SOSTheme.primaryRed : .clear
    }
}

#Preview {
    MapScreenView()
}
