import SwiftUI

struct WaitingGuideView: View {
    var initialType: EmergencyType? = nil
    var showsCloseButton: Bool = false
    var isEmergencyActive: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: EmergencyType?
    @State private var completedStepIDs: Set<String> = []

    private var content: WaitingGuideContent {
        if let selectedType {
            return .forType(selectedType)
        }
        return .general()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if !isEmergencyActive {
                    typePicker
                }
                checklistSection
                avoidSection
                alertSection
                callOperatorButton
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEmergencyActive ? "Guía ahora" : "Guía de espera")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            selectedType = initialType
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: selectedType?.icon ?? "list.bullet.clipboard.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(SOSTheme.headerGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(content.headline)
                        .font(.title3.weight(.bold))
                    Text(content.summary)
                        .font(.subheadline)
                        .foregroundStyle(SOSTheme.secondaryText)
                }
            }

            if isEmergencyActive {
                Text("Emergencia activa · sigue estos pasos mientras llega la unidad")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SOSTheme.primaryRed)
                    .padding(.top, 4)
            }

            progressBar
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
    }

    private var progressBar: some View {
        let total = content.doSteps.count
        let done = content.doSteps.filter { completedStepIDs.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progreso")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SOSTheme.secondaryText)
                Spacer()
                Text("\(done)/\(total)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SOSTheme.primaryRed)
            }
            ProgressView(value: Double(done), total: Double(max(total, 1)))
                .tint(SOSTheme.primaryRed)
        }
        .padding(.top, 8)
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tipo de emergencia")
                .font(.headline)

            Text("Elige para ver pasos específicos.")
                .font(.caption)
                .foregroundStyle(SOSTheme.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    typeChip(title: "General", icon: "list.bullet", type: nil)
                    ForEach(EmergencyType.allCases) { type in
                        typeChip(title: type.title, icon: type.icon, type: type)
                    }
                }
            }
        }
    }

    private func typeChip(title: String, icon: String, type: EmergencyType?) -> some View {
        let isSelected = selectedType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedType = type
                completedStepIDs.removeAll()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? .white : SOSTheme.primaryRed)
            .background(isSelected ? SOSTheme.primaryRed : SOSTheme.lightRed)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Qué sí hacer")
                .font(.headline)

            ForEach(Array(content.doSteps.enumerated()), id: \.element.id) { index, step in
                checklistRow(index: index + 1, step: step)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
    }

    private func checklistRow(index: Int, step: WaitingGuideStep) -> some View {
        let isDone = completedStepIDs.contains(step.id)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isDone {
                    completedStepIDs.remove(step.id)
                } else {
                    completedStepIDs.insert(step.id)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isDone ? Color.green : SOSTheme.primaryRed)
                        .frame(width: 28, height: 28)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(index)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: step.icon)
                            .foregroundStyle(SOSTheme.primaryRed)
                        Text(step.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .strikethrough(isDone)
                    }
                    Text(step.detail)
                        .font(.caption)
                        .foregroundStyle(SOSTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(isDone ? Color.green.opacity(0.08) : Color(.systemGray6).opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var avoidSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Qué evitar")
                .font(.headline)

            ForEach(content.avoidSteps) { step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SOSTheme.primaryRed)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.subheadline.weight(.semibold))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(SOSTheme.secondaryText)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
    }

    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Avisa al operador si…", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(SOSTheme.primaryRed)

            ForEach(content.whenToAlertOperator, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(SOSTheme.primaryRed)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(16)
        .background(SOSTheme.lightRed.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var callOperatorButton: some View {
        Link(destination: URL(string: "tel://911")!) {
            Label("Llamar al operador (911)", systemImage: "phone.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SOSTheme.headerGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        WaitingGuideView()
    }
}
