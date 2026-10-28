import SwiftUI

struct DispatcherChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DispatcherChatViewModel
    @FocusState private var isInputFocused: Bool

    init(
        emergencyType: EmergencyType?,
        unitNumber: String,
        etaText: String,
        phase: TrackingPhase,
        ticketId: String? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: DispatcherChatViewModel(
                emergencyType: emergencyType,
                unitNumber: unitNumber,
                etaText: etaText,
                phase: phase,
                ticketId: ticketId
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBanner

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(text: message.text, isOutgoing: message.isOutgoing)
                                    .id(message.id)
                            }

                            if viewModel.isTyping {
                                HStack {
                                    Text("Despachador está escribiendo…")
                                        .font(.caption)
                                        .foregroundStyle(SOSTheme.secondaryText)
                                        .padding(.horizontal, 4)
                                    Spacer()
                                }
                                .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: viewModel.isTyping) { _, _ in
                        scrollToBottom(proxy)
                    }
                }

                quickReplies

                inputBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Chat con despacho")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var statusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "ambulance.fill")
                .foregroundStyle(SOSTheme.primaryRed)
            VStack(alignment: .leading, spacing: 2) {
                Text("Unidad \(viewModel.unitNumber) · \(viewModel.phase.badge)")
                    .font(.caption.weight(.bold))
                Text(viewModel.emergencyType?.title ?? "Emergencia")
                    .font(.caption2)
                    .foregroundStyle(SOSTheme.secondaryText)
            }
            Spacer()
            Text(viewModel.etaText)
                .font(.caption.weight(.bold))
                .foregroundStyle(SOSTheme.primaryRed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private var quickReplies: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.availableQuickReplies, id: \.self) { reply in
                    Button {
                        viewModel.sendQuickReply(reply)
                    } label: {
                        Text(reply)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.white)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Escribe al despachador…", text: $viewModel.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                viewModel.sendDraft()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray
                        : SOSTheme.primaryRed
                    )
                    .clipShape(Circle())
            }
            .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                if viewModel.isTyping {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let last = viewModel.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

struct ChatBubble: View {
    let text: String
    let isOutgoing: Bool

    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 40) }
            Text(text)
                .font(.subheadline)
                .padding(12)
                .background(isOutgoing ? SOSTheme.primaryRed : Color.white)
                .foregroundStyle(isOutgoing ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
            if !isOutgoing { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    DispatcherChatView(
        emergencyType: .breathing,
        unitNumber: "A-31",
        etaText: "7 min",
        phase: .enCamino
    )
}
