import SwiftUI

struct DispatchingView: View {
    @ObservedObject var viewModel: EmergencyFlowViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(SOSTheme.lightRed, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.dispatchProgress)
                    .stroke(SOSTheme.primaryRed, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: viewModel.dispatchProgress)

                Image(systemName: "ambulance.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 8) {
                Text("Confirmando unidad")
                    .font(.title2.weight(.bold))

                if let type = viewModel.selectedType {
                    Text(type.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SOSTheme.primaryRed)
                }

                if let unit = viewModel.selectedAmbulance {
                    Text("\(unit.unitNumber) · \(unit.callSign)")
                        .font(.subheadline.weight(.semibold))
                } else if viewModel.assignmentMode == .closest {
                    Text("Asignando la más cercana")
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.secondaryText)
                }

                Text(viewModel.addressLabel)
                    .font(.subheadline)
                    .foregroundStyle(SOSTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 10) {
                dispatchStep(done: viewModel.dispatchProgress > 0.2, text: "Prioridad asignada")
                dispatchStep(done: viewModel.dispatchProgress > 0.5, text: "Contactando base")
                dispatchStep(done: viewModel.dispatchProgress > 0.8, text: "Confirmando unidad móvil")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                viewModel.goBack()
            } label: {
                Text("Cancelar")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SOSTheme.secondaryText)
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }

    private func dispatchStep(done: Bool, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? SOSTheme.primaryRed : Color(.tertiaryLabel))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(done ? .primary : SOSTheme.secondaryText)
            Spacer()
        }
    }
}

#Preview {
    DispatchingView(viewModel: EmergencyFlowViewModel())
}
