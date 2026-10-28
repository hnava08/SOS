import SwiftUI

struct EmergencyFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EmergencyFlowViewModel()

    var body: some View {
        Group {
            switch viewModel.step {
            case .selectType:
                EmergencyTypeSelectionView(viewModel: viewModel, onCancel: { dismiss() })
            case .confirmLocation:
                ConfirmLocationView(viewModel: viewModel)
            case .selectAmbulance:
                AmbulanceSelectionView(viewModel: viewModel)
            case .dispatching:
                DispatchingView(viewModel: viewModel)
            case .tracking:
                EmergencyTabView(
                    emergencyStatus: viewModel.makeEmergencyStatus(),
                    emergencyType: viewModel.selectedType,
                    ticketId: viewModel.activeTicket?.id,
                    useLivePolling: viewModel.activeTicket != nil,
                    onClose: {
                        dismiss()
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.step)
        .task {
            _ = await NotificationManager.shared.requestPermission()
        }
    }
}

#Preview {
    EmergencyFlowView()
}
