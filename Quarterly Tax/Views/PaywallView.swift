import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var purchasing = false
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    purchaseButton
                    legalLinks
                    privacyNote
                }
                .padding(24)
                .screenMaxWidth()
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Thank you!", isPresented: Binding(
                get: { successMessage != nil },
                set: { if !$0 { successMessage = nil } })) {
                Button("OK") { dismiss() }
            } message: {
                Text(successMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "jar.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Pay once. Panic never.")
                .font(.title.bold())
            Text("Unlock the full Safe Harbor engine and keep every payment proof — one payment, forever. No subscription.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow("target", "Safe Harbor precision engine", "Real compliance math: 90% / 100% / 110% rules + $1,000 exemption, instead of a 30% guess.")
            featureRow("camera.viewfinder", "Payment proof vault", "Photos + confirmation numbers, unlimited entries.")
            featureRow("doc.badge.arrow.up", "Tax Proof Pack PDF", "Audit-ready export of every payment.")
            featureRow("square.stack.3d.up.fill", "Full widget + Dynamic Island", "Deadline and jar progress on your Lock Screen.")
            featureRow("chart.line.uptrend.xyaxis", "Income jump warnings", "Get alerted when a big income change moves your target.")
            featureRow("calendar.badge.clock", "Multi-year archive", "Keep every year's record.")
        }
        .padding(.vertical, 6)
    }

    private func featureRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.green)
                .font(.title3)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var purchaseButton: some View {
        VStack(spacing: 10) {
            if let product = purchaseManager.lifetimeProduct {
                Button {
                    purchasing = true
                    Task {
                        let ok = await purchaseManager.purchase(product)
                        purchasing = false
                        if ok { successMessage = "Pro is unlocked. Pay once, own it forever." }
                    }
                } label: {
                    HStack {
                        if purchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Unlock Pro — \(product.displayPrice) once")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(purchasing)
            } else {
                VStack(spacing: 8) {
                    Text(purchaseManager.isLoading ? "Loading purchase options…" : "Purchase unavailable right now.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Try again") {
                        Task { await purchaseManager.loadProducts() }
                    }
                    .font(.subheadline)
                }
            }
            Button("Restore Purchases") {
                Task { await purchaseManager.restorePurchases() }
            }
            .font(.subheadline)
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/QuarterSafe/privacy.html")!)
                .font(.caption2)
            Link("Support", destination: URL(string: "https://asunnyboy861.github.io/QuarterSafe/support.html")!)
                .font(.caption2)
        }
    }

    private var privacyNote: some View {
        Text("One-time purchase. No subscription, no auto-renewal. Your data never leaves this device.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}
