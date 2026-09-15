import SwiftUI
import Combine

struct PaymentsView: View {
    @State private var store = AppStore.shared
    @State private var markPaidQuarter: Quarter?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Quarter.allCases) { quarter in
                        if let due = store.deadlines[quarter] {
                            QuarterPaymentCard(
                                quarter: quarter,
                                due: due,
                                paid: store.paymentsByQuarter[quarter] ?? 0,
                                suggested: suggestedFor(quarter),
                                onMarkPaid: { markPaidQuarter = quarter },
                                onPayOnIRS: { openIRS() })
                        }
                    }
                    historyCard
                }
                .padding(16)
                .screenMaxWidth()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Payments")
            .sheet(item: $markPaidQuarter) { quarter in
                MarkPaidSheet(quarter: quarter)
            }
            .onReceive(DeepLinkBus.shared.markPaidPublisher) { quarter in
                markPaidQuarter = quarter
            }
            .onAppear {
                if let q = PaymentsRouter.shared.openMarkPaid {
                    markPaidQuarter = q
                    PaymentsRouter.shared.openMarkPaid = nil
                }
            }
        }
    }

    private func suggestedFor(_ quarter: Quarter) -> Decimal {
        let paid = store.paymentsByQuarter[quarter] ?? 0
        return max(0, store.result.requiredTotal / 4 - paid)
    }

    private func openIRS() {
        guard let url = URL(string: "https://directpay.irs.gov/directpay/payment") else { return }
        UIApplication.shared.open(url)
    }

    private var historyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Payment history").font(.headline)
                if store.payments.isEmpty {
                    Text("No payments recorded yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.payments, id: \.id) { payment in
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(payment.quarterRaw) \(payment.taxYear) · \(Money.text(payment.amount, style: .exact))")
                                    .font(.subheadline)
                                Text("\(payment.method) · \(payment.paidAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

final class DeepLinkBus {
    static let shared = DeepLinkBus()
    let markPaidPublisher = NotificationCenter.default.publisher(for: Notification.Name("openMarkPaid"))
        .compactMap { ($0.object as? Quarter) }
}

struct QuarterPaymentCard: View {
    var quarter: Quarter
    var due: Date
    var paid: Decimal
    var suggested: Decimal
    var onMarkPaid: () -> Void
    var onPayOnIRS: () -> Void

    private var days: Int {
        DeadlineEngine.daysRemaining(until: due)
    }

    private var overdue: Bool { days < 0 && paid == 0 }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(quarter.key) · due \(due.formatted(date: .abbreviated, time: .omitted))")
                            .font(.headline)
                        if paid > 0 {
                            Label("Penalty-proof! Paid \(Money.text(paid))", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else if overdue {
                            Text("Overdue — pay as soon as possible")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else {
                            Text("Due in \(days) day\(days == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(days <= 14 ? Color.orange : .secondary)
                        }
                    }
                    Spacer()
                }
                if paid == 0 {
                    Text(Money.text(suggested))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    HStack(spacing: 12) {
                        Button {
                            onPayOnIRS()
                        } label: {
                            Label("Pay on IRS site", systemImage: "safari")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        Button {
                            onMarkPaid()
                        } label: {
                            Text("Mark as Paid")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                } else {
                    if paid < suggested {
                        Text("Still owed about \(Money.text(suggested - paid)) this quarter")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                        Button("Add another payment") { onMarkPaid() }
                            .font(.subheadline)
                            .tint(.green)
                    } else {
                        Label("All set — anything over rolls into the next quarter", systemImage: "arrow.right.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
