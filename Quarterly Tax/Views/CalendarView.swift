import SwiftUI

struct CalendarView: View {
    @State private var store = AppStore.shared

    struct Milestone: Identifiable {
        let id = UUID()
        let title: String
        let date: Date
        let symbol: String
        let color: Color
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    quarterCards
                    milestonesCard
                    educationCard
                }
                .padding(16)
                .screenMaxWidth()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Calendar")
        }
    }

    private var quarterCards: some View {
        VStack(spacing: 12) {
            ForEach(Quarter.allCases) { quarter in
                if let due = store.deadlines[quarter] {
                    quarterRow(quarter, due: due)
                }
            }
        }
    }

    private func quarterRow(_ quarter: Quarter, due: Date) -> some View {
        let days = DeadlineEngine.daysRemaining(until: due)
        let paid = store.paymentsByQuarter[quarter] ?? 0
        let isNext = store.nextDue?.quarter == quarter
        return GlassCard {
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(quarter.key)
                        .font(.title2.bold())
                        .foregroundStyle(isNext ? Color.green : .primary)
                    Text(due.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 110, alignment: .leading)
                Spacer()
                if paid > 0 {
                    Label("Paid \(Money.text(paid))", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text(days < 0 ? "Overdue" : "in \(max(0, days)) days")
                        .font(.subheadline)
                        .foregroundStyle(days < 0 ? Color.red : (isNext ? Color.orange : .secondary))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var milestones: [Milestone] {
        var list: [Milestone] = []
        let od = store.config.otherDeadlines
        if let d = DeadlineEngine.parseISO(od.forms1099) {
            list.append(Milestone(title: "1099 forms from clients", date: d, symbol: "doc.badge.clock", color: .blue))
        }
        if let d = DeadlineEngine.parseISO(od.annualFiling) {
            list.append(Milestone(title: "Annual tax filing", date: d, symbol: "flag.checkered", color: .green))
        }
        if let d = DeadlineEngine.parseISO(od.extensionFiling) {
            list.append(Milestone(title: "Extended filing deadline", date: d, symbol: "clock.arrow.circlepath", color: .orange))
        }
        return list.sorted { $0.date < $1.date }
    }

    private var milestonesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Other tax days").font(.headline)
                ForEach(milestones) { m in
                    HStack {
                        Image(systemName: m.symbol).foregroundStyle(m.color)
                        Text(m.title).font(.subheadline)
                        Spacer()
                        Text(m.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var educationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Heads up: IRS quarters aren't real quarters", systemImage: "info.circle")
                    .font(.headline)
                Text("Q2 only covers April–May (2 months!), and Q3 covers June–August. The short gap between Q1 and Q2 catches many gig workers off guard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Weekends and federal holidays shift deadlines — QuarterSafe already accounts for that.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
