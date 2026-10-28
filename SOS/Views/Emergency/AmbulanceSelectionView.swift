import SwiftUI
import UIKit

struct AmbulanceSelectionView: View {
    @ObservedObject var viewModel: EmergencyFlowViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.isLoadingAmbulances {
                Spacer()
                ProgressView("Buscando unidades cercanas…")
                Spacer()
            } else if let error = viewModel.ambulanceLoadError, viewModel.availableAmbulances.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(SOSTheme.primaryRed)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    Button("Reintentar") {
                        Task { await viewModel.loadAmbulances() }
                    }
                    .font(.headline)
                    .foregroundStyle(SOSTheme.primaryRed)
                    Link(destination: URL(string: "tel://911")!) {
                        Label("Llamar al 911", systemImage: "phone.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(SOSTheme.headerGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.addressLabel)
                            .font(.subheadline)
                            .foregroundStyle(SOSTheme.secondaryText)
                            .padding(.horizontal, 4)

                        closestCard

                        Text("O elige una unidad")
                            .font(.headline)
                            .padding(.top, 4)

                        ForEach(viewModel.availableAmbulances) { ambulance in
                            ambulanceCard(ambulance)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 28)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert("No se pudo pedir la ambulancia", isPresented: Binding(
            get: { viewModel.dispatchError != nil && viewModel.step == .selectAmbulance },
            set: { if !$0 { viewModel.dispatchError = nil } }
        )) {
            Button("Entendido", role: .cancel) { viewModel.dispatchError = nil }
            Button("Llamar 911") {
                if let url = URL(string: "tel://911") {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(viewModel.dispatchError ?? "")
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
                Text("Elegir ambulancia")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Más cercana o la que prefieras")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SOSTheme.headerGradient)
    }

    private var closestCard: some View {
        Button {
            viewModel.chooseClosest()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.white)
                    Text("Enviar la más cercana")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                }

                if let closest = viewModel.closestAmbulance {
                    Text("\(closest.unitNumber) · \(closest.callSign) · ETA \(closest.etaMinutes) min · \(String(format: "%.1f", closest.distanceKm)) km")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("\(closest.baseName) → \(closest.hospital)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                } else {
                    Text("Calcularemos la unidad disponible más próxima a tu ubicación.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SOSTheme.headerGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.closestAmbulance == nil)
        .accessibilityHint("Asigna automáticamente la ambulancia más cercana disponible")
    }

    private func ambulanceCard(_ ambulance: DispatchAmbulance) -> some View {
        Button {
            viewModel.chooseAmbulance(ambulance)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(ambulance.unitNumber)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(SOSTheme.primaryRed)
                    Text(ambulance.callSign)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(ambulance.etaMinutes) min")
                        .font(.headline)
                        .foregroundStyle(SOSTheme.primaryRed)
                }

                Text(ambulance.levelLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SOSTheme.lightRed)
                    .clipShape(Capsule())

                labeled("Base", ambulance.baseName)
                labeled("Hospital de referencia", ambulance.hospital)
                labeled("Equipo", ambulance.equipment)
                labeled("Tripulación", "\(ambulance.crewSize) personas")
                labeled("Distancia", String(format: "%.1f km", ambulance.distanceKm))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Unidad \(ambulance.unitNumber), \(ambulance.etaMinutes) minutos")
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption)
                .foregroundStyle(SOSTheme.secondaryText)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    AmbulanceSelectionView(viewModel: EmergencyFlowViewModel())
}
