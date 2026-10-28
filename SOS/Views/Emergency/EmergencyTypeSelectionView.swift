import SwiftUI
import UIKit

struct EmergencyTypeSelectionView: View {
    @ObservedObject var viewModel: EmergencyFlowViewModel
    var onCancel: () -> Void
    @ObservedObject private var network = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 10) {
                    if network.isDegraded {
                        OfflineBanner(
                            isOnline: false,
                            onCall911: {
                                if let url = URL(string: "tel://911") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    Text("¿Qué está pasando?")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    Text("Elige el tipo de emergencia para priorizar la unidad.")
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    ForEach(EmergencyType.allCases) { type in
                        Button {
                            viewModel.selectType(type)
                        } label: {
                            typeRow(type)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Nueva emergencia")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SOSTheme.headerGradient)
    }

    private func typeRow(_ type: EmergencyType) -> some View {
        HStack(spacing: 14) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(SOSTheme.headerGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(type.subtitle)
                    .font(.caption)
                    .foregroundStyle(SOSTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            Text(type.priorityLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(SOSTheme.primaryRed)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(SOSTheme.lightRed)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }
}

#Preview {
    EmergencyTypeSelectionView(viewModel: EmergencyFlowViewModel(), onCancel: {})
}
