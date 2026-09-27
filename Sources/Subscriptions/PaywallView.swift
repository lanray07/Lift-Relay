import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionStore.self) private var store
    @State private var selectedID: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill").font(.system(size: 60)).foregroundStyle(Theme.accent)
                    Text("paywall.headline").font(.largeTitle.bold())
                    Text("paywall.subtitle").foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 14) {
                        Benefit(text: "paywall.benefit.swaps", icon: "arrow.triangle.swap")
                        Benefit(text: "paywall.benefit.relay", icon: "arrow.triangle.2.circlepath")
                        Benefit(text: "paywall.benefit.time", icon: "timer")
                        Benefit(text: "paywall.benefit.voice", icon: "waveform")
                        Benefit(text: "paywall.benefit.profiles", icon: "building.2")
                    }
                    if store.isLoading { ProgressView().frame(maxWidth: .infinity) }
                    ForEach(store.products, id: \.id) { product in
                        Button { selectedID = product.id } label: {
                            HStack { VStack(alignment: .leading) { Text(product.displayName).font(.headline); Text(product.description).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(product.displayPrice).font(.headline); Image(systemName: selectedID == product.id ? "checkmark.circle.fill" : "circle") }
                                .padding().background(selectedID == product.id ? Theme.accent.opacity(0.18) : Theme.card, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                    }
                    if let product = store.products.first(where: { $0.id == selectedID }) {
                        Button("paywall.start") { Task { await store.purchase(product) } }.buttonStyle(PrimaryButtonStyle())
                    }
                    Button("paywall.restore") { Task { await store.restore() } }.frame(maxWidth: .infinity)
                    Text("paywall.renewal").font(.caption).foregroundStyle(.secondary)
                    HStack { Link("legal.terms", destination: URL(string: "https://liftrelay.app/terms")!); Spacer(); Link("legal.privacy", destination: URL(string: "https://liftrelay.app/privacy")!) }.font(.footnote)
                }.padding()
            }
            .navigationTitle("paywall.pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("action.close") { dismiss() } } }
            .task { AnalyticsClient.shared.track(.paywallViewed); if selectedID == nil { selectedID = store.products.first?.id } }
        }
    }
}

private struct Benefit: View {
    let text: LocalizedStringKey; let icon: String
    var body: some View { Label { Text(text) } icon: { Image(systemName: icon).foregroundStyle(Theme.accent) }.font(.headline) }
}
