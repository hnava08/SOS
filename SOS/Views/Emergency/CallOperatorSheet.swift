import SwiftUI

struct CallOperatorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let emergencyType: EmergencyType?
    let unitNumber: String
    let etaText: String
    let onConfirmCall: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(SOSTheme.lightRed)
                        .frame(width: 88, height: 88)
                    Image(systemName: "phone.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(SOSTheme.primaryRed)
                }
                .padding(.top, 12)

                VStack(spacing: 8) {
                    Text("Llamar al operador")
                        .font(.title2.weight(.bold))
                    Text("Te conectaremos con el despacho de emergencias (911). Ten a mano tu ubicación y el estado del paciente.")
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 10) {
                    infoRow(title: "Emergencia", value: emergencyType?.title ?? "Médica")
                    infoRow(title: "Unidad", value: unitNumber)
                    infoRow(title: "ETA", value: etaText)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        onConfirmCall()
                        dismiss()
                    } label: {
                        Label("Llamar ahora al 911", systemImage: "phone.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(SOSTheme.headerGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button("Cancelar") { dismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SOSTheme.secondaryText)
                }
            }
            .padding(20)
            .navigationTitle("Operador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SOSTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}

#Preview {
    CallOperatorSheet(
        emergencyType: .chestPain,
        unitNumber: "A-31",
        etaText: "8 min",
        onConfirmCall: {}
    )
}
