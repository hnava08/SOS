import SwiftUI
import MapKit

struct ConfirmLocationView: View {
    @ObservedObject var viewModel: EmergencyFlowViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition
    @State private var didApplyInitialLocation = false

    private let santaCruzPicks: [(name: String, coordinate: CLLocationCoordinate2D)] = [
        ("Plaza 24 de Septiembre", CLLocationCoordinate2D(latitude: -17.7836, longitude: -63.1811)),
        ("Equipetrol", CLLocationCoordinate2D(latitude: -17.7610, longitude: -63.1780)),
        ("Av. Monseñor Rivero", CLLocationCoordinate2D(latitude: -17.7780, longitude: -63.1840)),
        ("Plan 3000", CLLocationCoordinate2D(latitude: -17.8160, longitude: -63.1450))
    ]

    init(viewModel: EmergencyFlowViewModel) {
        self.viewModel = viewModel
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: viewModel.userCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                )
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            mapSection
            confirmPanel
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            if AppSettingsStore.shared.shareLocationInEmergency {
                locationManager.requestPermission()
                locationManager.startUpdating()
            } else {
                locationManager.applyFallbackIfNeeded()
                applyCoordinate(LocationManager.fallbackCoordinate, source: .fallback)
            }
            if !locationManager.permissionState.isUsableGPS {
                locationManager.applyFallbackIfNeeded()
                applyCoordinate(LocationManager.fallbackCoordinate, source: .fallback)
            }
        }
        .onReceive(locationManager.$userLocation) { coordinate in
            guard let coordinate else { return }
            // Solo auto-centrar con GPS la primera vez o si no hay pin manual.
            if locationManager.source == .manual, didApplyInitialLocation { return }
            applyCoordinate(coordinate, source: locationManager.source)
            didApplyInitialLocation = true
        }
        .onChange(of: locationManager.permissionState) { _, state in
            if !state.isUsableGPS {
                locationManager.applyFallbackIfNeeded()
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Confirmar ubicación")
                    .font(.headline)
                    .foregroundStyle(.white)
                if let type = viewModel.selectedType {
                    Text(type.title)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SOSTheme.headerGradient)
    }

    private var mapSection: some View {
        ZStack(alignment: .top) {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    Annotation("Tu ubicación", coordinate: viewModel.userCoordinate) {
                        ZStack {
                            Circle()
                                .fill(pinColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Circle()
                                .fill(pinColor)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        }
                    }
                }
                .mapStyle(.standard)
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        locationManager.setManualLocation(coordinate)
                        applyCoordinate(coordinate, source: .manual)
                    }
                }
            }

            LocationPermissionBanner(
                state: locationManager.permissionState,
                source: locationManager.source,
                accuracyText: accuracyText,
                onRequestPermission: {
                    locationManager.requestPermission()
                },
                onOpenSettings: {
                    locationManager.openSystemSettings()
                }
            )
            .padding(12)
        }
        .frame(maxHeight: .infinity)
    }

    private var confirmPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundStyle(SOSTheme.primaryRed)

                VStack(alignment: .leading, spacing: 4) {
                    Text(locationTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SOSTheme.secondaryText)
                    Text(viewModel.addressLabel)
                        .font(.body.weight(.semibold))
                    Text(helpText)
                        .font(.caption)
                        .foregroundStyle(SOSTheme.secondaryText)
                    if viewModel.isLocating {
                        Text("Actualizando dirección…")
                            .font(.caption)
                            .foregroundStyle(SOSTheme.secondaryText)
                    }
                }
            }

            if locationManager.permissionState.isUsableGPS, locationManager.source != .gps {
                Button("Usar GPS del iPhone") {
                    locationManager.preferGPS()
                    didApplyInitialLocation = false
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(SOSTheme.primaryRed)
            }

            if !locationManager.permissionState.isUsableGPS || locationManager.source != .gps {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(santaCruzPicks, id: \.name) { pick in
                            Button {
                                locationManager.setManualLocation(pick.coordinate)
                                applyCoordinate(pick.coordinate, source: .manual)
                            } label: {
                                Text(pick.name)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(SOSTheme.lightRed)
                                    .foregroundStyle(SOSTheme.primaryRed)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button {
                viewModel.confirmLocation()
            } label: {
                Text("Confirmar ubicación")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(SOSTheme.headerGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.white)
    }

    private var locationTitle: String {
        switch locationManager.source {
        case .gps: return "Ubicación GPS"
        case .fallback: return "Ubicación aproximada (Santa Cruz)"
        case .manual: return "Ubicación marcada en el mapa"
        }
    }

    private var helpText: String {
        if locationManager.permissionState.isUsableGPS {
            return "Puedes tocar el mapa para ajustar el punto exacto."
        }
        return "Toca el mapa o elige un punto de referencia para indicar dónde estás."
    }

    private var accuracyText: String? {
        guard let accuracy = locationManager.accuracyMeters, accuracy > 0, accuracy < 2000 else { return nil }
        return String(format: "Precisión ±%.0f m", accuracy)
    }

    private var pinColor: Color {
        locationManager.source == .gps ? .blue : SOSTheme.primaryRed
    }

    private func applyCoordinate(_ coordinate: CLLocationCoordinate2D, source: LocationSource) {
        viewModel.updateLocation(coordinate)
        viewModel.locationSource = source
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            )
        )
    }
}

#Preview {
    ConfirmLocationView(viewModel: EmergencyFlowViewModel())
}
