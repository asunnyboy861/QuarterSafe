import SwiftUI
import SwiftData

struct VaultView: View {
    @State private var store = AppStore.shared
    @State private var pdfURL: URL?
    @State private var showShare = false
    @State private var showPaywall = false
    @Query private var payments: [Payment]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    exportCard
                    proofList
                }
                .padding(16)
                .screenMaxWidth()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Vault")
            .sheet(isPresented: $showShare) {
                if let pdfURL {
                    ShareSheet(items: [pdfURL])
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var proPayments: [Payment] {
        PurchaseManager.shared.isPro ? payments : Array(payments.prefix(4))
    }

    private var exportCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Tax Proof Pack", systemImage: "doc.badge.arrow.up")
                    .font(.headline)
                Text("One PDF with every payment: dates, amounts, confirmation numbers, and your proof photos — the record the IRS can't dispute.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    exportPDF()
                } label: {
                    Label("Export PDF", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var proofList: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Payment proofs").font(.headline)
                if proPayments.isEmpty {
                    Text("Mark a payment as paid and attach a proof photo — it will live here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(proPayments, id: \.id) { payment in
                        HStack(alignment: .top, spacing: 12) {
                            if let data = payment.proofPhotoData,
                               let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 56, height: 56)
                                    .overlay(Image(systemName: "doc.text").foregroundStyle(.secondary))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(payment.quarterRaw) \(payment.taxYear) · \(Money.text(payment.amount, style: .exact))")
                                    .font(.subheadline.bold())
                                Text(payment.method)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !payment.confirmationNumber.isEmpty {
                                    Text("Conf # \(payment.confirmationNumber)")
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                                Text(payment.paidAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if !PurchaseManager.shared.isPro && payments.count > 4 {
                        Button("Show all \(payments.count) proofs — unlock Pro") {
                            showPaywall = true
                        }
                        .font(.subheadline)
                        .tint(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func exportPDF() {
        guard PurchaseManager.shared.isPro else {
            showPaywall = true
            return
        }
        guard let data = ProofEngine.generateAuditPackPDF(
            payments: payments,
            taxYear: store.currentTaxYear,
            version: "\(store.config.version) (rev \(store.config.reviewedDate))") else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuarterSafe-TaxProofPack-\(store.currentTaxYear).pdf")
        try? data.write(to: url)
        pdfURL = url
        showShare = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
