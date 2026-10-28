import SwiftUI

struct FirstAidTipsView: View {
    @Environment(\.dismiss) private var dismiss
    var showsCloseButton: Bool = false
    var tips: [FirstAidTip] = FirstAidTip.samples
    var title: String = "Primeros Auxilios"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(tips) { tip in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: tip.icon)
                                .font(.title2)
                                .foregroundStyle(SOSTheme.primaryRed)
                            Text(tip.title)
                                .font(.headline)
                        }

                        ForEach(Array(tip.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(SOSTheme.primaryRed)
                                    .clipShape(Circle())
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundStyle(SOSTheme.secondaryText)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: SOSTheme.shadow, radius: 8, y: 3)
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FirstAidTipsView()
    }
}
