import SwiftUI

struct HomeView: View {
    @State private var store = AppStore.shared
    @State private var showAddIncome = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var saveHintVisible = false
    var onNavigate: ((RootView.Tab) -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    countdownCard
                    jarCard
                    addIncomeButton
                    if let hint = store.lastSaveHint, saveHintVisible {
                        saveHintCard(hint)
                    }
                    if let jump = store.lastIncomeJumpWarning, PurchaseManager.shared.isPro {
                        incomeJumpCard(jump)
                    }
                    smallBalanceCard
                    privacyNote
                }
                .padding(16)
                .screenMaxWidth()
            }
            .background(Color(.systemBackground))
            .navigationTitle("QuarterSafe")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showAddIncome) {
                AddIncomeSheet()
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack { SettingsView() }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var countdownCard: some View {
        GlassCard {
            HStack(spacing: 20) {
                if let next = store.nextDue {
                    CountdownRing(daysRemaining: DeadlineEngine.daysRemaining(until: next.date))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(next.quarter.key) DUE IN")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(next.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                        Button("How to pay") {
                            onNavigate?(.payments)
                        }
                        .font(.subheadline)
                        .tint(.green)
                    }
                    Spacer()
                } else {
                    Text("Setting up deadlines…")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    private var jarCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(store.isSimpleMode ? "Simple mode · set aside 30%" : "Your tax jar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Money.text(max(0, store.result.requiredTotal - store.paidThisYear - (store.profile?.reservedJarBalance ?? 0))))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("to your tax jar")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                JarProgressBar(progress: store.jarProgress)
                if store.isSimpleMode {
                    Label("Add last year's tax in Settings for real Safe Harbor math", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var addIncomeButton: some View {
        Button {
            showAddIncome = true
        } label: {
            Label("Add Income", systemImage: "plus.circle.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .clipShape(Capsule())
        .accessibilityHint("Log a payment you received")
    }

    private func saveHintCard(_ hint: Decimal) -> some View {
        GlassCard {
            HStack {
                Image(systemName: "jar.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("This one: save \(Money.text(hint))")
                        .font(.headline)
                    Text("Move it aside right now and the jar stays full.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .onAppear {
            saveHintVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { saveHintVisible = false }
                store.lastSaveHint = nil
            }
        }
    }

    private func incomeJumpCard(_ growth: Double) -> some View {
        GlassCard {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.orange)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your income jumped \(Int((growth * 100).rounded()))%")
                        .font(.headline)
                    Text("Your jar target changed — tap to review in Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Review") { showSettings = true }
                    .font(.subheadline)
                    .tint(.green)
            }
        }
    }

    @ViewBuilder
    private var smallBalanceCard: some View {
        if store.yearToDateIncome > 0 && !store.result.needsQuarterlies {
            GlassCard {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No quarterly payments required")
                            .font(.headline)
                        Text("Your estimated tax is under $1,000 — settle in April.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private var privacyNote: some View {
        Text("Everything stays on this iPhone")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
    }
}
