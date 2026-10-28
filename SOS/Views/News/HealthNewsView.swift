import SwiftUI

struct HealthNewsView: View {
    @ObservedObject private var network = NetworkMonitor.shared
    private let articles: [HealthArticle] = HealthArticle.samples

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if network.isDegraded {
                    OfflineBanner(isOnline: false, compact: true)
                    Text("Mostrando noticias guardadas en el dispositivo. Se actualizarán al recuperar internet.")
                        .font(.caption)
                        .foregroundStyle(SOSTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(articles) { article in
                    HealthArticleCard(article: article)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Noticias de Salud")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct HealthArticle: Identifiable {
    let id = UUID()
    var title: String
    var summary: String
    var category: String
    var date: String
    var icon: String
}

extension HealthArticle {
    static let samples: [HealthArticle] = [
        HealthArticle(
            title: "Campaña de vacunación en Santa Cruz",
            summary: "Centros de salud amplían horarios para vacunas contra influenza y COVID-19 en el departamento.",
            category: "Prevención",
            date: "4 Ago 2026",
            icon: "syringe.fill"
        ),
        HealthArticle(
            title: "Línea 911: respuesta en menos de 5 minutos",
            summary: "El servicio de emergencias de Santa Cruz reduce tiempos de despacho con nuevo sistema de geolocalización.",
            category: "Emergencias",
            date: "2 Ago 2026",
            icon: "phone.badge.waveform.fill"
        ),
        HealthArticle(
            title: "Primeros auxilios básicos que todos deben conocer",
            summary: "Aprende RCP, manejo de heridas y posición lateral de seguridad. Cursos gratuitos este mes.",
            category: "Educación",
            date: "1 Ago 2026",
            icon: "heart.text.square.fill"
        )
    ]
}

struct HealthArticleCard: View {
    let article: HealthArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(article.category, systemImage: article.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SOSTheme.primaryRed)
                Spacer()
                Text(article.date)
                    .font(.caption)
                    .foregroundStyle(SOSTheme.secondaryText)
            }

            Text(article.title)
                .font(.headline)

            Text(article.summary)
                .font(.subheadline)
                .foregroundStyle(SOSTheme.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: SOSTheme.shadow, radius: 6, y: 2)
        )
    }
}

#Preview {
    NavigationStack {
        HealthNewsView()
    }
}
