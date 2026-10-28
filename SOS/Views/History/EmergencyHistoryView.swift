import SwiftUI

struct EmergencyHistoryView: View {
    @StateObject private var viewModel = EmergencyHistoryViewModel()
    @State private var showClearConfirm = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_BO")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Group {
            if viewModel.records.isEmpty {
                ContentUnavailableView(
                    "Sin emergencias",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Cuando pidas una ambulancia, el llamado aparecerá aquí con fecha, unidad y resultado.")
                )
            } else {
                List {
                    Section {
                        Text("\(viewModel.records.count) llamado\(viewModel.records.count == 1 ? "" : "s") registrado\(viewModel.records.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(SOSTheme.secondaryText)
                    }

                    Section("Recientes") {
                        ForEach(viewModel.records) { record in
                            NavigationLink {
                                EmergencyHistoryDetailView(record: record)
                            } label: {
                                historyRow(record)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.delete(record)
                                } label: {
                                    Label("Borrar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !viewModel.records.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Vaciar") { showClearConfirm = true }
                }
            }
        }
        .confirmationDialog(
            "¿Borrar todo el historial?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Borrar todo", role: .destructive) {
                viewModel.clearAll()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func historyRow(_ record: EmergencyHistoryRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.emergencyType?.icon ?? "ambulance.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(SOSTheme.headerGradient)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.emergencyTitle)
                    .font(.subheadline.weight(.semibold))
                Text("Unidad \(record.unitNumber) · \(dateFormatter.string(from: record.createdAt))")
                    .font(.caption)
                    .foregroundStyle(SOSTheme.secondaryText)
                Text(record.addressLabel)
                    .font(.caption2)
                    .foregroundStyle(SOSTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(record.outcome.title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(outcomeColor(record.outcome))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(outcomeColor(record.outcome).opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private func outcomeColor(_ outcome: EmergencyOutcome) -> Color {
        switch outcome {
        case .dispatched: return .orange
        case .arrived: return .green
        case .cancelled: return .gray
        }
    }
}

struct EmergencyHistoryDetailView: View {
    let record: EmergencyHistoryRecord

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_BO")
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        List {
            Section("Resumen") {
                LabeledContent("Tipo", value: record.emergencyTitle)
                LabeledContent("Unidad", value: record.unitNumber)
                LabeledContent("ETA inicial", value: "\(record.etaMinutes) min")
                LabeledContent("Resultado", value: record.outcome.title)
            }

            Section("Cuándo") {
                LabeledContent("Inicio", value: dateFormatter.string(from: record.createdAt))
                LabeledContent("Actualizado", value: dateFormatter.string(from: record.updatedAt))
            }

            Section("Ubicación") {
                Text(record.addressLabel)
                LabeledContent(
                    "Coordenadas",
                    value: String(format: "%.5f, %.5f", record.latitude, record.longitude)
                )
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EmergencyHistoryView()
    }
}
